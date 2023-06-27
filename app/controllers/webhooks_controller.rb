# frozen_string_literal: true

class WebhooksController < ApplicationController
  protect_from_forgery except: %i[github_webhook_catcher semaphore_webhook_catcher]
  before_action :verify_signature, only: %i[github_webhook_catcher semaphore_webhook_catcher]

  def github_webhook_catcher
    github_webhook_handler(params)
    render json: {status: :ok}
  end

  def semaphore_webhook_catcher
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

    sha_between = fetch_commit_history(repo, first_sha, last_sha)
    create_deploys_for_pull_requests(sha_between, branch, passed, time)
  end

  def verify_signature
    recieved_signature = request.headers['HTTP_X_HUB_SIGNATURE_256'] ||
                         request.headers['X-Semaphore-Signature-256']
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                                        ENV.fetch('GITHUB_WEBHOOK_SECRET'),
                                        request.body.read).to_s
    return if Rack::Utils.secure_compare(signature, recieved_signature.gsub('sha256=', ''))

    render json: {status: 403}, status: :forbidden
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
