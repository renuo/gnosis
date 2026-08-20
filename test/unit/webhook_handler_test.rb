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

    @semaphore_webhook_hash = {
      workflow: {
        id: '5432cce0-196d-4898-9385-c1d670e4a9e9'
      },
      revision: {
        branch: {
          name: 'main',
          commit_range: 'one_hash...another_hash'
        }
      },
      pipeline: {
        result: 'passed',
        done_at: '2021-03-03T12:00:00Z'
      },
      organization: {
        name: 'aneshodza'
      },
      repository: {
        slug: 'aneshodza/test-repo'
      }
    }

    commit = Struct.new(:sha)
    comparison = Struct.new(:commits)
    Octokit::Client.any_instance.stubs(:compare).returns(
      comparison.new([commit.new('one_hash'), commit.new('another_hash')])
    )

    @pull_request = FactoryBot.create(:pull_request, merge_commit_sha: 'one_hash')
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

  def test_handle_semaphore_creates_deployment_for_compared_commit
    assert_difference('Gnosis::PullRequestDeployment.count', 1) do
      Gnosis::WebhookHandler.new.handle_semaphore(@semaphore_webhook_hash)
    end

    deployment = Gnosis::PullRequestDeployment.last
    assert_equal @pull_request.id, deployment.pull_request_id
    assert_equal 'main', deployment.deploy_branch
    assert deployment.has_passed
    assert_equal 'https://aneshodza.semaphoreci.com/workflows/5432cce0-196d-4898-9385-c1d670e4a9e9/', deployment.url
    assert_equal Time.zone.parse('2021-03-03T12:00:00Z'), deployment.ci_date
  end

  def test_handle_semaphore_records_a_failed_pipeline
    @semaphore_webhook_hash[:pipeline][:result] = 'failed'
    Gnosis::WebhookHandler.new.handle_semaphore(@semaphore_webhook_hash)

    assert_not Gnosis::PullRequestDeployment.last.has_passed
  end

  def test_handle_semaphore_skips_commits_without_a_known_pull_request
    Gnosis::PullRequest.destroy_all

    assert_no_difference('Gnosis::PullRequestDeployment.count') do
      Gnosis::WebhookHandler.new.handle_semaphore(@semaphore_webhook_hash)
    end
  end

  def test_handle_semaphore_logs_and_swallows_an_unknown_comparison
    Octokit::Client.any_instance.stubs(:compare).raises(Octokit::NotFound)
    Rails.logger.expects(:error).with(regexp_matches(/comparison not found/i))

    assert_no_difference('Gnosis::PullRequestDeployment.count') do
      assert_nothing_raised { Gnosis::WebhookHandler.new.handle_semaphore(@semaphore_webhook_hash) }
    end
  end

  def test_handle_semaphore_logs_and_swallows_a_rate_limit
    Octokit::Client.any_instance.stubs(:compare).raises(Octokit::TooManyRequests)
    Rails.logger.expects(:error).with(regexp_matches(/rate limit/i))

    assert_no_difference('Gnosis::PullRequestDeployment.count') do
      assert_nothing_raised { Gnosis::WebhookHandler.new.handle_semaphore(@semaphore_webhook_hash) }
    end
  end
end
