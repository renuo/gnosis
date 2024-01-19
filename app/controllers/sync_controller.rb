# frozen_string_literal: true

class SyncController < ApplicationController
  def sync_pull_requests
    SyncJob.perform_later
    render plain: 'Pull request syncing started. This may take a while.'
  rescue StandardError => e
    Rails.logger.error(e)
    render plain: 'There was an error while syncing the pull requests, please check the logs.'
  end
end
