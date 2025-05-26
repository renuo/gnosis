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

  def test_update_pull_request
    PullRequest.auto_create_or_update(@github_webhook_hash)
    @github_webhook_hash[:pull_request][:state] = 'open'
    @github_webhook_hash[:pull_request][:merged] = false
    assert_difference('PullRequest.count', 0) do
      PullRequest.auto_create_or_update(@github_webhook_hash)
    end

    pr = PullRequest.last
    assert_equal 'open', pr.state
  end

  def test_closed_draft_pull_request_state
    webhook_hash = @github_webhook_hash.dup
    webhook_hash[:pull_request][:state] = 'closed'
    webhook_hash[:pull_request][:draft] = true
    webhook_hash[:pull_request][:merged] = false

    PullRequest.auto_create_or_update(webhook_hash)

    pr = PullRequest.find_by(url: webhook_hash[:pull_request][:html_url])
    assert_equal 'closed', pr.state
  end
end
