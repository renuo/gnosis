# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request do
    state { %w[open close merged].sample }
    url { 'example.com' }
    title { 'some pr' }
    source_branch { 'some other pr' }
    target_branch { 'main' }
    was_merged { false }
    merge_commit_sha { 'some_sha' }
    issue { Issue.first || null }
  end
end
