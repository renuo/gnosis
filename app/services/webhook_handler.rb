# frozen_string_literal: true

class WebhookHandler
  class << self
    Octokit.configure do |config|
      config.access_token = ENV.fetch('GITHUB_ACCESS_TOKEN')
    end
    CLIENT = Octokit::Client.new

    def handle_github(params)
      number = NumberExtractor.call(params)

      return unless number.present? && Issue.exists?(id: number)

      PullRequest.auto_create_or_update(params.merge(issue_id: number))
    end

    def handle_semaphore(params)
      range = params[:revision][:branch][:commit_range]
      branch = params[:revision][:branch][:name]
      repo = params[:repository][:slug]
      passed = params[:pipeline][:result] == 'passed'
      time = params[:pipeline][:done_at]

      org = params[:organization][:name]
      workflow_id = params[:workflow][:id]

      first_sha = range.split('...').first
      last_sha = range.split('...').last

      sha_between = fetch_commit_history(repo, first_sha, last_sha)
      create_deploys_for_pull_requests(semaphore_url(org, workflow_id), sha_between, branch, passed, time)
    end

    private

    def create_deploys_for_pull_requests(url, sha_between, branch, passed, time)
      sha_between.each do |sha|
        pr = PullRequest.find_by(merge_commit_sha: sha)
        next unless pr

        PullRequestDeployment.auto_create_or_update(branch, pr.id, url, passed, time)
      end
    end

    def fetch_commit_history(repo, first_commit, last_commit)
      comparison = CLIENT.compare(repo, first_commit, last_commit)
      comparison.commits.pluck(:sha)
    end

    def semaphore_url(org, workflow_id)
      "https://#{org}.semaphoreci.com/workflows/#{workflow_id}/"
    end
  end
end
