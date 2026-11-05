# frozen_string_literal: true

FactoryBot.define do
  factory :deployment, class: 'Gnosis::Deployment' do
    sequence(:url) { |n| "https://renuo.semaphoreci.com/workflows/#{n}/" }
    repository { 'renuo/example' }
    deploy_branch { 'main' }
    has_passed { true }
    ci_date { Time.zone.now }
  end

  factory :deployment_commit, class: 'Gnosis::DeploymentCommit' do
    deployment
    sequence(:sha) { |n| sprintf('%040x', n) }
    message { 'Bump rails from 8.0.1 to 8.0.2' }
  end
end
