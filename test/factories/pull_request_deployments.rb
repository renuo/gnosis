# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request_deployment do
    deploy_branch { 'main' }
    url { 'example.com' }
    has_passed { true }
    ci_date { Time.zone.now }

    pull_request { create(:pull_request) }
  end
end
