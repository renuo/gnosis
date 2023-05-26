# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request do
    action { %w[opened closed reopened].sample }
    url { 'example.com' }
    title { Faker::Lorem.sentence }
    source_branch { Faker::Lorem.word }
    target_branch { 'main' }
    was_merged { false }
    issue { Issue.first || null }
  end
end
