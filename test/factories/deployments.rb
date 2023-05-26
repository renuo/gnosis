# frozen_string_literal: true

FactoryBot.define do
  factory :deployment do
    deploy_branch { 'main' }
    url { 'example.com' }
    has_passed { true }

    pull_request { create(:pull_request) }
  end
end
