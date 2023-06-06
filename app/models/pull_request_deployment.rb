# frozen_string_literal: true

class PullRequestDeployment < GnosisApplicationRecord
  belongs_to :pull_request
  has_one :issue, through: :pull_request, source: :issue

  def self.auto_create_or_update(branch, pull_request_id, url, has_passed, ci_date_string)
    ci_date = Time.zone.parse(ci_date_string)
    deploy = PullRequestDeployment.find_or_initialize_by(deploy_branch: branch, pull_request_id: pull_request_id)
    deploy.update!(url: url, has_passed: has_passed, ci_date: ci_date)
  end
end
