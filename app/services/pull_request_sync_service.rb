# frozen_string_literal: true

class PullRequestSyncService
  def call
    init_client

    fetch_repositories.each do |repository|
      fetch_repository_pull_requests(repository).each do |pull_request|
        ticket_number = pull_request_ticket(pull_request)

        continue unless ticket_number.present?

        Rails.logger.info "Processing pull request #{pull_request[:html_url]}"

        pull_request_hash = pull_request.to_h
        pull_request_hash[:issue_id] = ticket_number
        pull_request_hash[:merged] = pull_request[:merged_at].present?

        PullRequest.auto_create_or_update(pull_request_hash)

        Rails.logger.info "Processing deployments for #{pull_request[:html_url]}"
      end
    end

    nil
  end

  def fetch_repositories
    # @client.org_repositories(ENV.fetch('GITHUB_ORGANIZATION_NAME'), type: :all)
    [{
      # full_name: 'renuo/legacy-import-test'
      full_name: 'renuo/gifcoins2'
     }]
  end

  def fetch_repository_pull_requests(repository)
    # @client.pull_requests(repository[:full_name], state: :all)
    [@client.pull_requests(repository[:full_name], state: :all).first]
  end

  def pull_request_ticket(pull_request)
    NumberExtractor.call(pull_request: pull_request)

  end

  def filter_pull_requests(pull_requests)
    pull_requests.select do |pull_request|
      NumberExtractor.call(pull_request: pull_request)
    end
  end

  def pull_request_status(pull_request)
    @client.status(pull_request[:head][:repo][:full_name], pull_request[:head][:sha])
  end

  def init_client
    @client = Octokit::Client.new(access_token: ENV.fetch( 'GITHUB_ACCESS_TOKEN' ))
  end
end
