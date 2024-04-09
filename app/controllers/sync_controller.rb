# frozen_string_literal: true

class SyncController < ApplicationController
  before_action :require_admin

  def sync_pull_requests
    SyncJob.perform_now
    render plain: 'Pull request syncing started. This may take a while.'
  rescue StandardError => e
    Rails.logger.error(e)
    render plain: 'There was an error while syncing the pull requests, please check the logs.',
           status: :internal_server_error
  end
end
