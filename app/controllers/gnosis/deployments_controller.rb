# frozen_string_literal: true

module Gnosis
  class DeploymentsController < ::ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize

    DEPLOYMENTS_PER_PAGE = 20
    DEPLOY_BRANCH = 'main'

    def index
      scope = Deployment.for_project(@project).where(deploy_branch: DEPLOY_BRANCH)

      @deployment_count = scope.count
      @deployment_pages = Redmine::Pagination::Paginator.new(@deployment_count, DEPLOYMENTS_PER_PAGE, params[:page])

      deployments = scope.includes(:commits)
                         .order(ci_date: :desc, id: :desc)
                         .limit(DEPLOYMENTS_PER_PAGE)
                         .offset(@deployment_pages.offset)
                         .to_a

      @deployment_rows = deployment_rows(deployments)
    end

    def current_menu_item
      :gnosis_deployments
    end

    private

    # [deployment, pull requests grouped by issue, commits without a ticketed pull request]
    # Commits are matched to pull requests here rather than when the deployment arrives,
    # because GitHub's merge webhook can come in after Semaphore's.
    def deployment_rows(deployments)
      pull_requests_by_url = PullRequestDeployment.where(url: deployments.map(&:url), deploy_branch: DEPLOY_BRANCH)
                                                  .includes(pull_request: :issue)
                                                  .group_by(&:url)
                                                  .transform_values { |rows| rows.map(&:pull_request) }
      pull_requests_by_sha = PullRequest.includes(:issue)
                                        .where(merge_commit_sha: deployments.flat_map { |d| d.commits.map(&:sha) })
                                        .index_by(&:merge_commit_sha)

      deployments.map do |deployment|
        matched = deployment.commits.filter_map { |commit| pull_requests_by_sha[commit.sha] }
        pull_requests = (pull_requests_by_url.fetch(deployment.url, []) + matched).uniq
        untracked = deployment.commits.reject { |commit| pull_requests_by_sha.key?(commit.sha) }

        [deployment, pull_requests.sort_by(&:issue_id).group_by(&:issue), untracked]
      end
    end
  end
end
