# frozen_string_literal: true

module Gnosis
  class PullRequest < ApplicationRecord
    belongs_to :issue
    has_many :pull_request_deployments, dependent: :destroy

    def self.auto_create_or_update(webhook_params)
      pull_request_data = webhook_params[:pull_request]

      state = pull_request_data[:merged] ? 'merged' : pull_request_data[:state]
      state = 'draft' if state == 'open' && pull_request_data[:draft]
      return if Issue.find_by(id: webhook_params[:issue_id]).nil?

      pr = PullRequest.find_or_initialize_by(url: pull_request_data[:html_url])
      github_updated_at = pull_request_data[:updated_at] && Time.zone.parse(pull_request_data[:updated_at].to_s)
      return if pr.persisted? && github_updated_at && pr.github_updated_at.present? && github_updated_at <= pr.github_updated_at

      pr.update!(state: state,
                 url: pull_request_data[:html_url],
                 title: pull_request_data[:title],
                 source_branch: pull_request_data[:head][:ref],
                 target_branch: pull_request_data[:base][:ref],
                 was_merged: pull_request_data[:merged],
                 merge_commit_sha: pull_request_data[:merge_commit_sha],
                 github_updated_at: github_updated_at || pr.github_updated_at,
                 issue_id: webhook_params[:issue_id])
    end
  end
end
