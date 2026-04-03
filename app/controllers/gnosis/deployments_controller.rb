# frozen_string_literal: true

module Gnosis
  class DeploymentsController < ::ApplicationController
    before_action :find_project_by_project_id, :authorize

    PER_PAGE = 20

    def index
      scope = PullRequestDeployment
              .joins(pull_request: :issue)
              .where(issues: { project_id: @project.id })
              .where(deploy_branch: 'main')

      @deployment_count = scope.count
      @deployment_pages = Redmine::Pagination::Paginator.new(@deployment_count, PER_PAGE, params[:page])

      @deployments = scope
                     .includes(pull_request: :issue)
                     .order(ci_date: :desc)
                     .limit(PER_PAGE)
                     .offset(@deployment_pages.offset)
    end
  end
end
