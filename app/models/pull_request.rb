# frozen_string_literal: true

class PullRequest < GnosisApplicationRecord
  belongs_to :issue
  has_many :pull_request_deployments, dependent: :destroy

  def self.auto_create_or_update(params)
    state = params[:pull_request][:merged] ? 'merged' : params[:pull_request][:state]
    state = 'draft' if params[:pull_request][:draft]
    pr = PullRequest.find_or_initialize_by(url: params[:pull_request][:html_url])
    pr.update!(state: state, url: params[:pull_request][:html_url],
               title: params[:pull_request][:title], source_branch: params[:pull_request][:head][:ref],
               target_branch: params[:pull_request][:base][:ref], was_merged: params[:pull_request][:merged],
               merge_commit_sha: params[:pull_request][:merge_commit_sha], issue_id: params[:issue_id])
  end
end
