# frozen_string_literal: true

require_relative '../test_helper'

class SyncControllerTest < ActionController::TestCase
  def setup
    @controller = Gnosis::SyncController.new
    @request.session[:user_id] = 1 # admin
  end

  def test_sync_pull_requests_runs_the_job
    Gnosis::SyncJob.expects(:perform_now)

    get :sync_pull_requests
    assert_response :success
    assert_match(/syncing started/i, response.body)
  end

  def test_sync_pull_requests_reports_failures
    Gnosis::SyncJob.stubs(:perform_now).raises(StandardError, 'boom')
    Rails.logger.expects(:error).with(instance_of(StandardError))

    get :sync_pull_requests
    assert_response :internal_server_error
    assert_match(/check the logs/i, response.body)
  end

  def test_sync_pull_requests_requires_admin
    @request.session[:user_id] = nil
    Gnosis::SyncJob.expects(:perform_now).never

    get :sync_pull_requests
    assert_response :redirect
  end
end
