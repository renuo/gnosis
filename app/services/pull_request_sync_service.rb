# frozen_string_literal: true

class PullRequestSyncService
  def call
    fetch_repositories.each do |repository|
      fetch_repository_pull_requests(repository).each do |pull_request|
        Rails.logger.info "Processing pull request #{pull_request[:html_url]}"

        pull_request_hash = pull_request.to_h
        pull_request_hash[:merged] = pull_request[:merged_at].present?

        WebhookHandler.new.handle_github(pull_request: pull_request_hash)
      end
    end
  end

  def fetch_repositories
    client.org_repositories(ENV.fetch('GITHUB_ORGANIZATION_NAME'), type: :private)
  end

  def fetch_repository_pull_requests(repository)
    client.pull_requests(repository[:full_name], state: :all)
  end

  def client
    @client ||= Octokit::Client.new(access_token: ENV.fetch('GITHUB_ACCESS_TOKEN'), auto_paginate: true)
  end
end
