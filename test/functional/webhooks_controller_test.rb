# frozen_string_literal: true

require_relative '../test_helper'

class WebhookCatchControllerControllerTest < ActionController::TestCase
  def setup
    @controller = WebhooksController.new

    commit = Struct.new(:sha)
    comparison_result_struct = Struct.new(:commits)

    comparison_result = comparison_result_struct.new([
                                                       commit.new('another_hash'),
                                                       commit.new('in_between_hash'),
                                                       commit.new('one_hash')
                                                     ])

    Octokit::Client.any_instance.stubs(:compare).returns(comparison_result)

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
        draft: false
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
        done_at: '2021-03-03T12:00:00Z'
      },
      organization: {
        name: 'aneshodza',
      },
      repository: {
        slug: 'aneshodza/test-repo',
      }
    }

    FactoryBot.build_list(:pull_request, 3).each(&:save!)
    PullRequest.first.update!(merge_commit_sha: 'one_hash')
    PullRequest.first(2).last.update!(merge_commit_sha: 'in_between_hash')
    PullRequest.first(3).last.update!(merge_commit_sha: 'another_hash')
  end

  def test_create_pull_request
    @request.headers['X-Hub-Signature-256'] =
      'sha256=09a2bb0a3c451c2dd5c2c227e05b0f2da426211b1b67c09bc724b1ea851538ce'
    assert_difference('PullRequest.count', 1) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end

    new_pr = PullRequest.last
    assert_equal 'merged', new_pr.state
    assert_equal 1, new_pr.issue_id
  end

  def test_update_pull_request_existing_url
    PullRequest.auto_create_or_update(@github_webhook_hash.merge(issue_id: Issue.first.id))
    @request.headers['X-Hub-Signature-256'] =
      'sha256=4256f0ad4e317084d15e7ffeecb6e66667f45d12fcbd5ad0fecf4c0e31802ce2'
    @github_webhook_hash[:pull_request][:state] = 'open'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
    assert @response.status == 200
    assert 'closed', PullRequest.last.state
  end

  def test_create_pull_request_no_issue
    @request.headers['X-Hub-Signature-256'] = 'sha256=b15df5baab94e31571b043e810545ec49075dedb0dd7aa78b8f185501248c918'
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/420-some-feature-no-issue'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
  end

  def test_create_pull_request_no_issue_in_branch_name
    @request.headers['X-Hub-Signature-256'] = 'sha256=2d44814be7f48dce09dc87544720819beab8be0747381d0c45c4301f1eef2a1b'
    @github_webhook_hash[:pull_request][:head][:ref] = 'feature/some-feature-no-issue'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
    # Just because there is no issue, doesn't mean it should fail
    assert @response.status == 200
  end

  def test_pr_with_invalid_sha
    @request.headers['X-Hub-Signature-256'] = 'sha256=invalid'
    assert_difference('PullRequest.count', 0) do
      post :github_webhook_catcher, params: @github_webhook_hash, as: :json
    end
    assert @response.status == 403
  end

  def test_create_deploys
    @request.headers['X-Semaphore-Signature-256'] = 'f88bf226e3fd7cbf28de748adfdd65a4372184d8daac01e2bd2aab1537f9981d'
    assert_difference('PullRequestDeployment.count', 3) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
  end

  def test_deploy_with_invalid_sha
    @request.headers['X-Semaphore-Signature-256'] = 'invalid'
    assert_difference('PullRequestDeployment.count', 0) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
    assert @response.status == 403
  end

  def test_deploy_no_pr
    PullRequest.destroy_all
    @request.headers['X-Semaphore-Signature-256'] = 'f88bf226e3fd7cbf28de748adfdd65a4372184d8daac01e2bd2aab1537f9981d'
    assert_difference('PullRequestDeployment.count', 0) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
    assert @response.status == 200
  end
end
