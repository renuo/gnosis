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

  def test_index_shows_ticket_link
    get :index, params: { project_id: @project.identifier }
    assert_response :success
    assert_select 'a', text: /#{@pr.issue.subject}/
  end

  def test_index_empty_project
    project2 = Project.create!(name: 'EmptyProject', identifier: 'emptyproject')
    project2.enabled_modules.find_or_create_by!(name: 'gnosis')

    get :index, params: { project_id: project2.identifier }
    assert_response :success
    assert_select 'p.nodata', text: 'No deployments found for this project.'
  end
end
