# frozen_string_literal: true

module Gnosis
  class WebhookHandler
    def initialize
      @client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_ACCESS_TOKEN'))
    end

    def handle_github(params)
      issue = Issue.find_by(id: NumberExtractor.call(params))
      return unless issue

      PullRequest.auto_create_or_update(issue, params)
    end

    def handle_semaphore(params)
      range = params[:revision][:branch][:commit_range]
      branch = params[:revision][:branch][:name]
      repo = params[:repository][:slug]
      passed = params[:pipeline][:result] == 'passed'
      time = params[:pipeline][:done_at]

      org = params[:organization][:name]
      workflow_id = params[:workflow][:id]

      first_sha, last_sha = range.split('...')

      sha_between = fetch_commit_history(repo, first_sha, last_sha)
      create_deploys_for_pull_requests(semaphore_url(org, workflow_id), sha_between, branch, passed, time)
    rescue Octokit::NotFound => e
      Rails.logger.error("[Gnosis::WebhookHandler] Comparison not found for #{repo}: #{e.message}")
    rescue Octokit::TooManyRequests => e
      Rails.logger.error("[Gnosis::WebhookHandler] GitHub rate limit exceeded #{repo}: #{e.message}")
    end

    private

    def create_deploys_for_pull_requests(url, sha_between, branch, passed, time)
      deployed_pull_requests = PullRequest.open.where(head_sha: sha_between)
                                          .or(PullRequest.merged.where(merge_commit_sha: sha_between))
      deployed_pull_requests.each do |pr|
        PullRequestDeployment.auto_create_or_update(branch, pr.id, url, passed, time)
      end
    end

    def fetch_commit_history(repo, first_commit, last_commit)
      comparison = @client.compare(repo, first_commit, last_commit)
      comparison.commits.pluck(:sha)
    end

    def semaphore_url(org, workflow_id)
      "https://#{org}.semaphoreci.com/workflows/#{workflow_id}/"
    end
  end
end
