# frozen_string_literal: true

class WebhooksController < ApplicationController
  protect_from_forgery except: %i[github_webhook_catcher semaphore_webhook_catcher]

  Octokit.configure do |config|
    config.access_token = ENV.fetch('GITHUB_ACCESS_TOKEN', nil)
  end
  CLIENT = Octokit::Client.new

  def github_webhook_catcher
    unless verify_signature(request.body.read, request.env['HTTP_X_HUB_SIGNATURE_256'],
                            ENV.fetch('GITHUB_WEBHOOK_SECRET', nil))
      return render json: {status: 403}, status: :forbidden
    end

    github_webhook_handler(params)

    render json: {status: :ok}
  end

  def semaphore_webhook_catcher
    unless verify_signature(request.body.read, "sha256=#{request.headers['X-Semaphore-Signature-256']}",
                            ENV.fetch('SEMAPHORE_WEBHOOK_SECRET', nil))
      return render json: {status: 403}, status: :forbidden
    end

    semaphore_webhook_handler(params)

    render json: {status: :ok}
  end

  def check_if_login_required
    false # No login required as this uses the "verify_signature" for validation
  end

  private

  def github_webhook_handler(params)
    number = NumberExtractor.call(params)

    return unless number.present? && Issue.exists?(id: number)

    PullRequest.auto_create_or_update(params.merge(issue_id: number))
  end

  def semaphore_webhook_handler(params)
    range = params[:revision][:branch][:commit_range]
    branch = params[:revision][:branch][:name]
    repo = params[:repository][:slug]
    passed = params[:pipeline][:result] == 'passed'
    time = params[:pipeline][:done_at]

    first_sha = range.split('...').first
    last_sha = range.split('...').last

    sha_between = fetch_commit_history(repo, first_sha, last_sha)
    create_deploys_for_pull_requests(sha_between, branch, passed, time)
  end

  def verify_signature(payload_body, recieved_signature, secret)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload_body)}"
    Rack::Utils.secure_compare(signature, recieved_signature)
  end

  def fetch_commit_history(repo, first_commit, last_commit)
    comparison = CLIENT.compare(repo, first_commit, last_commit)
    comparison.commits.pluck(:sha)
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
