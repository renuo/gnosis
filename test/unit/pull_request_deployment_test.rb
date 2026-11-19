# frozen_string_literal: true

require_relative '../test_helper'

class PullRequestDeploymentTest < ActiveSupport::TestCase
  def test_belongs_to_pull_request
    FactoryBot.create(:pull_request_deployment)
    assert_equal 1, Gnosis::PullRequest.where(id: Gnosis::PullRequestDeployment.first.pull_request_id).count
  end

  def test_auto_create_or_update_updates_existing_deployment
    FactoryBot.create(:pull_request)
    deploy = FactoryBot.create(:pull_request_deployment)

    assert_difference 'Gnosis::PullRequestDeployment.count', 0 do
      Gnosis::PullRequestDeployment.auto_create_or_update(
        deploy.deploy_branch, deploy.pipeline_file, deploy.pull_request_id, 'aneshodza.ch', !deploy.has_passed,
        deploy.ci_date.to_s
      )
    end

    assert_equal deploy.reload.url, 'aneshodza.ch'
  end

  def test_auto_create_or_update_new_branch
    FactoryBot.create(:pull_request)
    deploy = FactoryBot.create(:pull_request_deployment)

    assert_difference 'Gnosis::PullRequestDeployment.count', 1 do
      Gnosis::PullRequestDeployment.auto_create_or_update(
        "some branch that doesn't exist", deploy.pipeline_file, deploy.pull_request_id, deploy.url,
        deploy.has_passed, deploy.ci_date.to_s
      )
    end

    assert_equal 2, Gnosis::PullRequestDeployment.count
  end

  def test_auto_create_or_update_updates_the_deployment_of_the_same_pipeline
    deploy = FactoryBot.create(:pull_request_deployment, deploy_branch: 'main',
                                                         pipeline_file: 'production-ch-deploy.yml')

    assert_no_difference 'Gnosis::PullRequestDeployment.count' do
      Gnosis::PullRequestDeployment.auto_create_or_update(
        'main', 'production-ch-deploy.yml', deploy.pull_request_id, 'https://example.com/rerun', true,
        deploy.ci_date.to_s
      )
    end

    assert_equal 'https://example.com/rerun', deploy.reload.url
  end

  def test_auto_create_or_update_keeps_the_deployments_of_other_pipelines_of_the_branch
    deploy = FactoryBot.create(:pull_request_deployment, deploy_branch: 'main',
                                                         pipeline_file: 'production-ch-deploy.yml')

    assert_difference 'Gnosis::PullRequestDeployment.count', 1 do
      Gnosis::PullRequestDeployment.auto_create_or_update(
        'main', 'production-de-deploy.yml', deploy.pull_request_id, deploy.url, true, deploy.ci_date.to_s
      )
    end

    assert_equal %w[production-ch-deploy.yml production-de-deploy.yml],
                 Gnosis::PullRequestDeployment.where(pull_request_id: deploy.pull_request_id)
                                              .order(:pipeline_file).pluck(:pipeline_file)
  end

  def test_target_label_names_the_target_of_the_pipeline
    deploy = FactoryBot.build(:pull_request_deployment, deploy_branch: 'main',
                                                        pipeline_file: 'production-ch-deploy.yml')

    assert_equal 'production-ch', deploy.target_label
  end

  def test_target_label_names_the_review_app_of_a_feature_branch
    deploy = FactoryBot.build(:pull_request_deployment, deploy_branch: 'feature/1-login',
                                                        pipeline_file: 'review-app-deploy.yml')

    assert_equal 'review-app', deploy.target_label
  end

  def test_target_label_is_empty_for_a_pipeline_named_after_its_branch
    deploy = FactoryBot.build(:pull_request_deployment, deploy_branch: 'main', pipeline_file: 'main-deploy.yml')

    assert_nil deploy.target_label
  end

  def test_target_label_is_empty_for_a_deployment_recorded_without_a_pipeline
    deploy = FactoryBot.build(:pull_request_deployment, deploy_branch: 'main', pipeline_file: nil)

    assert_nil deploy.target_label
  end
end
