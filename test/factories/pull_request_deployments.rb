# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request_deployment, class: 'Gnosis::PullRequestDeployment' do
    deploy_branch { 'main' }
    url { 'example.com' }
    has_passed { true }
    ci_date { Time.zone.now }

    pull_request { create(:pull_request) }

    after(:create) do |pr_deployment|
      Gnosis::Deployment.find_or_create_by!(url: pr_deployment.url, deploy_branch: pr_deployment.deploy_branch) do |run|
        run.repository = pr_deployment.pull_request.repository
        run.has_passed = pr_deployment.has_passed
        run.ci_date = pr_deployment.ci_date
      end
    end
  end
end
