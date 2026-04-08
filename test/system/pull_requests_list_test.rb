# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../gnosis_system_test")

class PullRequestListTest < GnosisSystemTest
  def setup
    login
    @prs = []
    3.times do |_i|
      @prs << FactoryBot.create(:pull_request, issue_id: 1)
    end
    FactoryBot.create(:pull_request_deployment, pull_request_id: @prs[0].id)
    FactoryBot.create(:pull_request_deployment, pull_request_id: @prs[0].id, deploy_branch: 'develop')
    FactoryBot.create(:pull_request_deployment, pull_request_id: @prs[1].id, deploy_branch: 'develop')
    visit 'issues/1'
  end

  def test_view_open
    assert page.has_content?('Pull Requests')
  end

  def test_no_prs
    visit 'issues/2'
    assert page.has_content?('There are currently no PRs open for this issue')
  end

  def test_prs_all_info_listed
    @prs.each do |pr|
      assert page.has_content?(pr.title)
      assert page.has_content?(pr.state)
      assert_includes page.find("#pr-#{pr.id}")['href'], pr.url
    end
  end

  def test_deployments_all_info_listed
    @prs.each do |pr|
      pr.pull_request_deployments.each do |deployment|
        assert page.has_content?(deployment.deploy_branch)
        assert_includes page.find("#deployment-#{deployment.id}")['href'], deployment.url
        assert page.has_content?(deployment.ci_date.utc.strftime('%d.%m.%Y %H:%M'))
        assert page.has_content?(deployment.has_passed ? '✅' : '❌')
      end
    end
  end

  def test_pr_state_icons_displayed
    @prs.each do |pr|
      assert page.has_content?(pr.state)
    end
  end

  def test_draft_state_icon_displayed
    FactoryBot.create(:pull_request, issue_id: 1, state: 'draft')
    visit 'issues/1'
    assert page.has_content?('draft')
  end

  def test_closed_state_icon_displayed
    FactoryBot.create(:pull_request, issue_id: 1, state: 'closed')
    visit 'issues/1'
    assert page.has_content?('closed')
  end

  def test_tree_connectors_displayed
    assert page.has_text?('├──') || page.has_text?('└──')
  end
end
