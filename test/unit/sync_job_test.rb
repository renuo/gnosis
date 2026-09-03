# frozen_string_literal: true

require_relative '../test_helper'

class SyncJobTest < ActiveSupport::TestCase
  def test_perform_runs_the_sync_service
    Gnosis::PullRequestSyncService.any_instance.expects(:call)

    Gnosis::SyncJob.perform_now
  end
end
