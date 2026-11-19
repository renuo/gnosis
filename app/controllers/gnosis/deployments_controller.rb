# frozen_string_literal: true

module Gnosis
  class DeploymentsController < ::ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize

    DEPLOYMENTS_PER_PAGE = 20
    def index
      base_scope = PullRequestDeployment
                   .joins(pull_request: :issue)
                   .where(issues: { project_id: @project.id })
                   .where(deploy_branch: 'main')

      pipeline_runs = base_scope.group(:url, :pipeline_file)
      @deployment_count = pipeline_runs.count.size
      @deployment_pages = Redmine::Pagination::Paginator.new(@deployment_count, DEPLOYMENTS_PER_PAGE, params[:page])

      page_runs = pipeline_runs
                  .order(Arel.sql('MAX(gnosis_pull_request_deployments.ci_date) DESC'))
                  .limit(DEPLOYMENTS_PER_PAGE)
                  .offset(@deployment_pages.offset)
                  .pluck(:url, :pipeline_file)

      deployments = base_scope
                    .includes(pull_request: :issue)
                    .where(url: page_runs.map(&:first))
                    .order(ci_date: :desc)

      @grouped_deployments = deployments.group_by { |deployment| [deployment.url, deployment.pipeline_file] }
                                        .slice(*page_runs)
                                        .sort_by { |_run, deps| -deps.first.ci_date.to_i }
                                        .map do |(url, _pipeline_file), deps|
        deployments_by_issue = deps.sort_by { |d| d.pull_request.issue_id }
                                   .group_by { |d| d.pull_request.issue_id }
        [url, deps, deployments_by_issue]
      end
    end

    def current_menu_item
      :gnosis_deployments
    end
  end
end
