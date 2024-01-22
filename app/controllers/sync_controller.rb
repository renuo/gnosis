# frozen_string_literal: true

class SyncController < ApplicationController
  before_action :require_admin

  def sync_pull_requests
    count_before = PullRequest.count
    PullRequestSyncService.new.call
    count_after = PullRequest.count
    render plain: "Synced #{count_after - count_before} pull requests."
  rescue StandardError => e
    Rails.logger.error(e)
    render plain: 'There was an error while syncing the pull requests, please check the logs.'
  end
end
