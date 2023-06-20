# frozen_string_literal: true

class PullRequest < GnosisApplicationRecord
  belongs_to :issue
  has_many :pull_request_deployments, dependent: :destroy

  def self.auto_create_or_update(params)
    pr = params[:pull_request]
    pull_request = PullRequest.find_or_initialize_by(url: pr[:html_url])
    pull_request.update!(state: state(params, pr), url: pr[:html_url],
               title: pr[:title], source_branch: pr[:head][:ref],
               target_branch: pr[:base][:ref], was_merged: pr[:merged],
               merge_commit_sha: pr[:merge_commit_sha], issue_id: params[:issue_id])
  end

  def self.state(params, pr)
    return 'merged' if pr[:merged]
    return 'draft' if pr[:draft]

    pr[:state]
  end
end
