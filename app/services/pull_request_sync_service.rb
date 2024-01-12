# frozen_string_literal: true

class PullRequestSyncService
  def call
    init_client

    fetch_repositories.each do |repository|
      fetch_repository_pull_requests(repository).each do |pull_request|
        ticket_number = NumberExtractor.call(pull_request: pull_request)

        continue if ticket_number.blank?

        Rails.logger.info "Processing pull request #{pull_request[:html_url]} for ticket #{ticket_number}"

        pull_request_hash = pull_request.to_h
        pull_request_hash[:issue_id] = ticket_number
        pull_request_hash[:merged] = pull_request[:merged_at].present?

        WebhookHandler.handle_github(pull_request_hash)
      end
    end

    nil
  end

  def fetch_repositories
    @client.org_repositories(ENV.fetch('GITHUB_ORGANIZATION_NAME'), type: :all)
  end

  def fetch_repository_pull_requests(repository)
    @client.pull_requests(repository[:full_name], state: :all)
  end

  def init_client
    @client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_ACCESS_TOKEN'))
  end
end
