# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/mock'

class PullRequestSyncServiceTest < ActiveSupport::TestCase
  def setup
    @github_repositories = [
      { full_name: 'aneshodza/test-repo' },
    ]

    @github_pull_requests = [
       {
        state: 'closed',
        html_url: 'https://github.com/aneshodza/test-repo/pull/17',
        title: 'Create something',
        head: {
          ref: 'feature/1-some-feature'
        },
        base: {
          ref: 'main'
        },
        merged_at: '2021-03-03T12:00:00Z',
        merge_commit_sha: '19a89f0050eacf201ccd058d5e28cddf2b035bfc',
        draft: false
      }
    ]

    Octokit::Client.any_instance.stubs(:new).returns(@github_repositories)
    Octokit::Client.any_instance.stubs(:org_repositories).returns(@github_repositories)
    Octokit::Client.any_instance.stubs(:pull_requests).returns(@github_pull_requests)
  end

  def test_import_pull_requests
    instance = PullRequestSyncService.new
    instance.stub(:fetch_repositories, [{ name: 'renuo/legacy-import-test' }]) do
      assert_equal 0, PullRequest.count
      instance.call
      assert_equal 1, PullRequest.count
    end
  end
end
