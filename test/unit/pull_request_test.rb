# frozen_string_literal: true

require_relative '../test_helper'

class PullRequestTest < ActiveSupport::TestCase
  EARLIER = '2024-01-01T10:00:00Z'
  LATER = '2024-01-01T11:00:00Z'

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
        merge_commit_sha: '19a89f0050eacf201ccd058d5e28cddf2b035bfc',
        updated_at: LATER
      },
      issue_id: 1
    }
  end

  def test_create_pull_request
    assert_difference('Gnosis::PullRequest.count', 1) do
      Gnosis::PullRequest.auto_create_or_update(@github_webhook_hash)
    end

    pr = Gnosis::PullRequest.last
    assert_equal 'merged', pr.state
    assert_equal Time.zone.parse(LATER), pr.github_updated_at
  end

  def test_update_pull_request
    webhook_hash = @github_webhook_hash.dup
    webhook_hash[:pull_request] = webhook_hash[:pull_request].merge(state: 'open', merged: false, updated_at: EARLIER)

    Gnosis::PullRequest.auto_create_or_update(webhook_hash)
    webhook_hash[:pull_request] = webhook_hash[:pull_request].merge(state: 'closed', merged: false, updated_at: LATER)
    assert_difference('Gnosis::PullRequest.count', 0) do
      Gnosis::PullRequest.auto_create_or_update(webhook_hash)
    end

    pr = Gnosis::PullRequest.last
    assert_equal 'closed', pr.state
  end

  def test_no_duplicate_urls
    url = 'example.com'
    FactoryBot.create(:pull_request, url: url)

    assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:pull_request, url: url) }
  end

  def test_out_of_order_webhook_does_not_overwrite_a_newer_state
    Gnosis::PullRequest.auto_create_or_update(@github_webhook_hash) # merged, at LATER

    stale_hash = @github_webhook_hash.dup
    stale_hash[:pull_request] = stale_hash[:pull_request].merge(state: 'open', merged: false, updated_at: EARLIER)
    assert_difference('Gnosis::PullRequest.count', 0) do
      Gnosis::PullRequest.auto_create_or_update(stale_hash)
    end

    pr = Gnosis::PullRequest.last
    assert_equal 'merged', pr.state
  end

  def test_out_of_order_webhook_does_not_reopen_a_more_recently_closed_pull_request
    webhook_hash = @github_webhook_hash.dup
    webhook_hash[:pull_request] = webhook_hash[:pull_request].merge(state: 'closed', merged: false, updated_at: LATER)
    Gnosis::PullRequest.auto_create_or_update(webhook_hash)

    stale_hash = @github_webhook_hash.dup
    stale_hash[:pull_request] = stale_hash[:pull_request].merge(state: 'open', merged: false, updated_at: EARLIER)
    Gnosis::PullRequest.auto_create_or_update(stale_hash)

    pr = Gnosis::PullRequest.last
    assert_equal 'closed', pr.state
  end

  def test_closed_draft_pull_request_state
    webhook_hash = @github_webhook_hash.dup
    webhook_hash[:pull_request] = webhook_hash[:pull_request].merge(state: 'closed', draft: true, merged: false)

    Gnosis::PullRequest.auto_create_or_update(webhook_hash)

    pr = Gnosis::PullRequest.find_by(url: webhook_hash[:pull_request][:html_url])
    assert_equal 'closed', pr.state
  end
end
