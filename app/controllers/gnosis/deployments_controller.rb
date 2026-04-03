# frozen_string_literal: true

module Gnosis
  class DeploymentsController < ::ApplicationController
    before_action :find_project_by_project_id, :authorize

    def index
      @deployments_by_branch = PullRequestDeployment
                               .joins(pull_request: :issue)
                               .where(issues: { project_id: @project.id })
                               .includes(pull_request: :issue)
                               .order(ci_date: :desc)
                               .group_by(&:deploy_branch)
    end
  end
end
