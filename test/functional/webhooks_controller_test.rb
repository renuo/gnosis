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
      'sha256=a61084e5bafb012607e8b4ea9f37260774bf1f00617861f2ae7aef73888234f7'
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
      'sha256=ed37b875f6877950542db3adbb9ba9d53ecb071970f90b234c37f2acd48e1cb3'
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
    @request.headers['X-Hub-Signature-256'] = 'sha256=5660dd5179a31c18d5b064cc4ee0293f76c5b9e61ed22be9894ba7b585005109'
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
    assert_difference('Deployment.count', 3) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
  end

  def test_deploy_with_invalid_sha
    @request.headers['X-Semaphore-Signature-256'] = 'invalid'
    assert_difference('Deployment.count', 0) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
    assert @response.status == 403
  end

  def test_deploy_no_pr
    PullRequest.destroy_all
    @request.headers['X-Semaphore-Signature-256'] = 'f88bf226e3fd7cbf28de748adfdd65a4372184d8daac01e2bd2aab1537f9981d'
    assert_difference('Deployment.count', 0) do
      post :semaphore_webhook_catcher, params: @semaphore_webhook_hash, as: :json
    end
    assert @response.status == 200
  end
end
