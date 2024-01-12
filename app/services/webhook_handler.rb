class WebhookHandler
  class << self
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

      first_sha = range.split('...').first
      last_sha = range.split('...').last

      sha_between = fetch_commit_history(repo, first_sha, last_sha)
      create_deploys_for_pull_requests(sha_between, branch, passed, time)
    end

    private

    def create_deploys_for_pull_requests(sha_between, branch, passed, time)
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

    def url
      "https://#{params[:organization][:name]}.semaphoreci.com/workflows/#{params[:workflow][:id]}/"
    end
  end
end
