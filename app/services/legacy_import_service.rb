# frozen_string_literal: true

class LegacyImportService
  def call
    init_client

    fetch_repositories.each do |repository|
      filter_pull_requests(fetch_repository_pull_requests(repository)).each do |pull_request|
        ticket_number = pull_request_ticket(pull_request)

        puts "Processing pull request #{pull_request[:html_url]}"

        # puts pull_request.inspect

        PullRequest.auto_create_or_update({
                                            pull_request: {
                                              merged: pull_request[:merged_at].present?,
                                              state: pull_request[:state],
                                              html_url: pull_request[:html_url],
                                              title: pull_request[:title],
                                              head: {
                                                ref: pull_request[:head][:ref],
                                              },
                                              base: {
                                                ref: pull_request[:base][:ref],
                                              },
                                              merge_commit_sha: pull_request[:merge_commit_sha],
                                            },
                                            issue_id: ticket_number
                                          })

      end
    end

    nil
  end

  def fetch_repositories
    # @client.org_repositories(ENV.fetch('GITHUB_ORGANIZATION_NAME'), type: :all)
    [{
      full_name: 'renuo/legacy-import-test'
     }]
  end

  def fetch_repository_pull_requests(repository)
    [@client.pull_requests(repository[:full_name], state: :all).first]
  end

  def pull_request_ticket(pull_request)
    # pull_request.dig(:head, :ref)&.match?(/feature\/\d+/) || pull_request.dig(:body)&.match?(/TICKET-\d+/)
    NumberExtractor.call(pull_request: pull_request)

  end

  def filter_pull_requests(pull_requests)
    pull_requests.select do |pull_request|
      NumberExtractor.call(pull_request: pull_request)
      # pull_request.dig(:head, :ref)&.match?(/feature\/\d+/) || pull_request.dig(:body)&.match?(/TICKET-\d+/)
      # pull_request_ticket(pull_request)
    end
  end

  def pull_request_status(pull_request)
    @client.status(pull_request[:head][:repo][:full_name], pull_request[:head][:sha])
  end

  def pull_request_deployments
    @client.deployments(pull_request[:head][:repo][:full_name], pull_request[:head][:sha])
  end

  def init_client
    @client = Octokit::Client.new(access_token: ENV.fetch( 'GITHUB_ACCESS_TOKEN' ))
  end
end
