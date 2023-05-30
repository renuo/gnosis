# frozen_string_literal: true

require_relative '../test_helper'

class WebhookCatchControllerControllerTest < ActionController::TestCase
  def setup
    @controller = WebhooksController.new

    Octokit::Client.any_instance.stubs(:commits).returns([
                                                           { sha: 'another_hash' },
                                                           { sha: 'in_between_hash' },
                                                           { sha: 'one_hash' }
                                                         ])

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
      }
    }

    @semaphore_webhook_hash = {
      workflow: {
        id: '5432cce0-196d-4898-9385-c1d670e4a9e9',
      },
      revision: {
        branch: {
          name: 'main',
          commit_range: 'one_hash...another_hash'
        }
      },
      pipeline: {
        result: 'passed',
      },
      organization: {
        name: 'aneshodza',
      },
      repository: {
        slug: 'aneshodza/test-repo',
      }
    }
  end

  def test_create_pull_request
    assert_difference('PullRequest.count', 1) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end

    new_pr = PullRequest.last
    assert_equal 'merged', new_pr.state
    assert_equal 1, new_pr.issue_id
  end

  def test_create_pull_request_no_issue
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/420-some-feature-no-issue'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
  end

  def test_create_pull_request_no_issue_in_branch_name
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/some-feature-no-issue'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
    # Just because there is no issue, doesn't mean it should fail
    assert @response.status == 200
  end

  def test_create_deploys
    FactoryBot.build_list(:pull_request, 3).each(&:save!)
    PullRequest.first.update!(merge_commit_sha: 'one_hash')
    PullRequest.first(2).last.update!(merge_commit_sha: 'in_between_hash')
    PullRequest.first(3).last.update!(merge_commit_sha: 'another_hash')

    assert_difference('Deployment.count', 3) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
  end
end
