# frozen_string_literal: true

class WebhooksController < ApplicationController
  protect_from_forgery except: %i[github_webhook_catcher semaphore_webhook_catcher]

  def github_webhook_catcher
    unless verify_signature(request.body.read, request.env['HTTP_X_HUB_SIGNATURE_256'],
                            ENV.fetch('GITHUB_WEBHOOK_SECRET'))
      return render json: {status: 403}, status: :forbidden
    end

    github_webhook_handler(params)

    render json: {status: :ok}
  end

  def semaphore_webhook_catcher
    unless verify_signature(request.body.read, "sha256=#{request.headers['X-Semaphore-Signature-256']}",
                            ENV.fetch('SEMAPHORE_WEBHOOK_SECRET'))
      return render json: {status: 403}, status: :forbidden
    end

    semaphore_webhook_handler(params)

    render json: {status: :ok}
  end

  private

  def github_webhook_handler(params)
    numbers = params[:pull_request][:head][:ref].match(%r{/(\d+)}) || []

    return unless numbers.length.positive? && Issue.exists?(id: numbers[1])

    PullRequest.auto_create_or_update(params.merge(issue_id: numbers[1]))
  end

  def semaphore_webhook_handler(params)
    range = params[:revision][:branch][:commit_range]
    branch = params[:revision][:branch][:name]
    repo = params[:repository][:slug]
    passed = params[:pipeline][:result] == 'passed'
    time = params[:pipeline][:done_at]

    first_sha = range.split('...').first
    last_sha = range.split('...').last

    sha_between = fetch_commit_history(repo, branch, first_sha, last_sha)
    create_deploys_for_pull_requests(sha_between, branch, passed, time)
  end

  def verify_signature(payload_body, recieved_signature, secret)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload_body)}"
    Rack::Utils.secure_compare(signature, recieved_signature)
  end

  def fetch_commit_history(repo, branch, first_commit, last_commit)
    commit_sha_list = CLIENT.commits(repo, branch).pluck(:sha)

    first_commit_index = commit_sha_list.index(first_commit)
    last_commit_index = commit_sha_list.index(last_commit)

    commit_sha_list[last_commit_index..first_commit_index]
  end

  def create_deploys_for_pull_requests(sha_between, branch, passed, time)
    sha_between.each do |sha|
      pr = PullRequest.find_by(merge_commit_sha: sha)
      next unless pr

      PullRequestDeployment.auto_create_or_update(branch, pr.id, url, passed, time)
    end
  end

  def url
    "https://#{params[:organization][:name]}.semaphoreci.com/workflows/#{params[:workflow][:id]}/"
  end
end
