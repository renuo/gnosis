# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request do
    state { %w[open close merged].sample }
    url { 'example.com' }
    title { Faker::Lorem.sentence }
    source_branch { Faker::Lorem.word }
    target_branch { 'main' }
    was_merged { false }
    merge_commit_sha { Faker::Lorem.characters(number: 40) }
    issue { Issue.first || null }
  end
end
