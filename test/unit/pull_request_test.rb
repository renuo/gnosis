# frozen_string_literal: true

require_relative '../test_helper'

class PullRequestTest < ActiveSupport::TestCase
  def setup
    @github_webhook_hash = {
      pull_request: {
        state: 'closed',
        html_url: 'https://github.com/aneshodza/test-repo/pull/17',
        title: 'Create something',
        head: {
          ref: 'feature/1-some-feature'
        },
        base: {
          ref: 'main'
        },
        merged: true,
        merge_commit_sha: '19a89f0050eacf201ccd058d5e28cddf2b035bfc'
      },
      issue_id: 1
    }
  end

  def test_create_pull_request
    assert_difference('PullRequest.count', 1) do
      PullRequest.auto_create_or_update(@github_webhook_hash)
    end

    pr = PullRequest.last
    assert_equal 'merged', pr.state
  end
end
