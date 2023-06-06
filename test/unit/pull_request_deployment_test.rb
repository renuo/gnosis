# frozen_string_literal: true

require_relative '../test_helper'

class PullRequestDeploymentTest < ActiveSupport::TestCase
  def test_belongs_to_pull_request
    FactoryBot.create(:pull_request_deployment)
    assert_equal 1, PullRequest.where(id: PullRequestDeployment.first.pull_request_id).count
  end

  def test_auto_create_or_update_updates_existing_deployment
    FactoryBot.create(:pull_request)
    deploy = FactoryBot.create(:pull_request_deployment)

    assert_difference 'PullRequestDeployment.count', 0 do
      PullRequestDeployment.auto_create_or_update(deploy.deploy_branch, deploy.pull_request_id, 'aneshodza.ch',
                                       !deploy.has_passed, deploy.ci_date.to_s)
    end

    assert_equal deploy.reload.url, 'aneshodza.ch'
  end

  def test_auto_create_or_update_new_branch
    FactoryBot.create(:pull_request)
    deploy = FactoryBot.create(:pull_request_deployment)

    assert_difference 'PullRequestDeployment.count', 1 do
      PullRequestDeployment.auto_create_or_update("some branch that doesn't exist", deploy.pull_request_id, deploy.url,
                                       deploy.has_passed, deploy.ci_date.to_s)
    end

    assert_equal 2, PullRequestDeployment.count
  end
end
