# frozen_string_literal: true

require_relative '../test_helper'
class PullRequestSyncServiceTest < Minitest::Test
  def test
    allow_any_instance_of(PullRequestSyncService).to receive(:fetch_repositories).and_return([{name: 'renuo/legacy-import-test'}])
    expect(PullRequest.count).to eq(0)

    PullRequestSyncService.new.call

    expect(PullRequest.count).to eq(1)
  end
end
