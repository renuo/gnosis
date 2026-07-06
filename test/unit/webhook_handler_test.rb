# frozen_string_literal: true

require_relative '../test_helper'

class WebhookHandlerTest < ActiveSupport::TestCase
  def setup
    @github_webhook_hash = {
      pull_request: {
        state: 'open',
        html_url: 'https://github.com/aneshodza/test-repo/pull/17',
        title: 'Create something',
        head: {
          ref: 'feature/1-some-feature'
        },
        base: {
          ref: 'main'
        },
        merged: false,
        merge_commit_sha: '19a89f0050eacf201ccd058d5e28cddf2b035bfc'
      }
    }
  end

  def test_handle_github_creates_pull_request_for_existing_issue
    assert_difference('Gnosis::PullRequest.count', 1) do
      Gnosis::WebhookHandler.new.handle_github(@github_webhook_hash)
    end
  end

  def test_handle_github_skips_when_no_issue_number_can_be_extracted
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/some-feature-no-issue'
    assert_no_difference('Gnosis::PullRequest.count') do
      Gnosis::WebhookHandler.new.handle_github(@github_webhook_hash)
    end
  end

  def test_handle_github_skips_when_extracted_issue_does_not_exist
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/999999-no-such-issue'
    assert_no_difference('Gnosis::PullRequest.count') do
      Gnosis::WebhookHandler.new.handle_github(@github_webhook_hash)
    end
  end
end
