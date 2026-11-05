# frozen_string_literal: true

require_relative '../test_helper'

class DeploymentsControllerTest < ActionController::TestCase
  def setup
    @controller = Gnosis::DeploymentsController.new
    @project = Project.first
    @request.session[:user_id] = 1 # admin

    role = Role.find_or_create_by!(name: 'Manager')
    role.add_permission!(:view_deployments)
    @project.enabled_modules.find_or_create_by!(name: 'gnosis')

    @pr = FactoryBot.create(:pull_request, issue_id: 1)
    @deployment_main = FactoryBot.create(:pull_request_deployment, pull_request: @pr, deploy_branch: 'main')
    @deployment_staging = FactoryBot.create(
      :pull_request_deployment,
      pull_request: @pr,
      deploy_branch: 'staging',
      url: 'https://staging.example.com'
    )
  end

  def test_index_shows_only_main_branch_deployments
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select 'a[href=?]', @deployment_main.url
    assert_select 'a[href=?]', @deployment_staging.url, count: 0
  end

  def test_index_shows_deployment_details
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select 'a[href=?]', @deployment_main.url
    assert_select 'a[href=?]', @pr.url
  end

  def test_index_shows_ticket_in_pivot_table
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-pivot-ticket a', text: "##{@pr.issue_id} #{@pr.issue.subject}"
  end

  def test_index_shows_ticket_summary
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-pivot-ticket a', text: /#{Regexp.escape(@pr.issue.subject)}/
  end

  def test_index_shows_deployment_card_structure
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 1
    assert_select '.deployment-card-header'
  end

  def test_index_groups_deployments_by_url
    pr2 = FactoryBot.create(:pull_request, issue_id: 2)
    FactoryBot.create(
      :pull_request_deployment,
      pull_request: pr2,
      deploy_branch: 'main',
      url: @deployment_main.url
    )

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 1
    assert_select '.deployment-card table.list tbody tr', 4
  end

  def test_index_empty_project
    project2 = Project.create!(name: 'EmptyProject', identifier: 'emptyproject')
    project2.enabled_modules.find_or_create_by!(name: 'gnosis')

    get :index, params: { project_id: project2.identifier }
    assert_response :success
    assert_select 'p.nodata', text: 'No deployments found for this project.'
  end

  def test_index_lists_a_deployment_without_any_ticket
    deployment = FactoryBot.create(:deployment, repository: @pr.repository, ci_date: 1.hour.from_now)
    commit = FactoryBot.create(:deployment_commit, deployment: deployment, message: 'Bump rails from 8.0.1 to 8.0.2')

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 2
    assert_select '.deployment-no-ticket', text: 'No ticket'
    assert_select '.deployment-commit a[href=?]', "https://github.com/#{@pr.repository}/commit/#{commit.sha}",
                  text: /Bump rails from 8\.0\.1 to 8\.0\.2/
  end

  def test_index_lists_ticketed_and_untracked_changes_of_the_same_deployment
    deployment = Gnosis::Deployment.find_by!(url: @deployment_main.url)
    FactoryBot.create(:deployment_commit, deployment: deployment, sha: @pr.merge_commit_sha, message: 'Ticketed change')
    FactoryBot.create(:deployment_commit, deployment: deployment, message: 'Untracked change')

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 1
    assert_select 'a[href=?]', @pr.url
    assert_select '.deployment-commit', 1
    assert_select '.deployment-commit', text: /Untracked change/
  end

  def test_index_matches_a_pull_request_merged_after_the_deployment_arrived
    deployment = FactoryBot.create(:deployment, repository: @pr.repository)
    FactoryBot.create(:deployment_commit, deployment: deployment, sha: 'late_sha')
    late_pr = FactoryBot.create(:pull_request, issue_id: 2, merge_commit_sha: 'late_sha', title: 'Merged late')

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-pr-title a[href=?]', late_pr.url
    assert_select '.deployment-commit', 0
  end

  def test_index_shows_a_deployment_without_change_details
    FactoryBot.create(:deployment, repository: @pr.repository)

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 2
    assert_select '.deployment-no-ticket', text: 'No change details available.'
  end

  def test_index_ignores_deployments_of_repositories_outside_the_project
    FactoryBot.create(:deployment, repository: 'renuo/unrelated')
    FactoryBot.create(:deployment, repository: nil)
    FactoryBot.create(:deployment, repository: @pr.repository, deploy_branch: 'staging')

    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select '.deployment-card', 1
  end

  def test_index_paginates_deployments
    FactoryBot.create_list(:deployment, Gnosis::DeploymentsController::DEPLOYMENTS_PER_PAGE,
                           repository: @pr.repository, ci_date: 1.day.ago)

    get :index, params: { project_id: @project.identifier, page: 2 }
    assert_response :success
    assert_select '.deployment-card', 1
  end
end
