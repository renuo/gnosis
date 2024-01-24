# frozen_string_literal: true

class PullRequest < GnosisApplicationRecord
  belongs_to :issue
  has_many :pull_request_deployments, dependent: :destroy

  def self.auto_create_or_update(webhook_params)
    state = webhook_params[:pull_request][:merged] ? 'merged' : webhook_params[:pull_request][:state]
    state = 'draft' if webhook_params[:pull_request][:draft]

    return if Issue.find_by(id: webhook_params[:issue_id]).nil?

    pr = PullRequest.find_or_initialize_by(url: webhook_params[:pull_request][:html_url])
    pr.update!(state: state,
               url: webhook_params[:pull_request][:html_url],
               title: webhook_params[:pull_request][:title], source_branch:
               webhook_params[:pull_request][:head][:ref],
               target_branch: webhook_params[:pull_request][:base][:ref],
               was_merged: webhook_params[:pull_request][:merged],
               merge_commit_sha: webhook_params[:pull_request][:merge_commit_sha],
               issue_id: webhook_params[:issue_id])
  end
end
