# frozen_string_literal: true

class SyncJob < ApplicationJob
  def perform
    info('Starting with pull request sync')
    PullRequestSyncService.new.call
    info('End pull request sync')
  end

  private

  def info(msg)
    Rails.logger.info('[PullRequestSyncJob] --- #{msg}')
  end
end
