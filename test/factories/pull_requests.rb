# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request, class: 'Gnosis::PullRequest' do
    state { 'merged' }
    sequence(:url) { |n| "example.com/#{n}" }
    title { 'some pr' }
    source_branch { 'some other pr' }
    target_branch { 'main' }
    was_merged { true }
    merge_commit_sha { 'some_sha' }
    issue { Issue.first || null }
  end
end
