# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../gnosis_system_test")

class DeploymentsPageTest < GnosisSystemTest
  def setup
    login
    @project = Project.first
    role = Role.find_or_create_by!(name: 'Manager')
    role.add_permission!(:view_deployments)
    @project.enabled_modules.find_or_create_by!(name: 'gnosis')

    @pr1 = FactoryBot.create(:pull_request, issue_id: 1)
    @pr2 = FactoryBot.create(:pull_request, issue_id: 2)
    @deploy1 = FactoryBot.create(:pull_request_deployment, pull_request: @pr1, deploy_branch: 'main')
    @deploy2 = FactoryBot.create(:pull_request_deployment, pull_request: @pr2, deploy_branch: 'main')
    @deploy3 = FactoryBot.create(:pull_request_deployment, pull_request: @pr1, deploy_branch: 'staging')
  end

  def test_deployments_page_accessible
    visit "projects/#{@project.identifier}/gnosis/deployments"
    assert page.has_content?('Deployments')
  end

  def test_deployments_grouped_by_branch
    visit "projects/#{@project.identifier}/gnosis/deployments"
    assert page.has_content?('main')
    assert page.has_content?('staging')
  end

  def test_deployment_shows_pull_request_info
    visit "projects/#{@project.identifier}/gnosis/deployments"
    assert page.has_content?(@pr1.title)
    assert page.has_content?(@pr2.title)
  end

  def test_deployment_shows_ticket_info
    visit "projects/#{@project.identifier}/gnosis/deployments"
    assert page.has_content?(Issue.find(1).subject)
    assert page.has_content?(Issue.find(2).subject)
  end

  def test_empty_deployments
    Gnosis::PullRequestDeployment.destroy_all
    visit "projects/#{@project.identifier}/gnosis/deployments"
    assert page.has_content?('No deployments found for this project.')
  end
end
