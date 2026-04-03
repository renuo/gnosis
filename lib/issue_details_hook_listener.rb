# frozen_string_literal: true

class IssueDetailsHookListener < Redmine::Hook::ViewListener
  def view_issues_show_description_bottom(context={})
    return '' unless User.current.allowed_to?(:view_list, nil, :global => true)

    @context = context
    setup
    <<-HTML
      <hr/>
      <strong>Pull Requests</strong>

      <div style="background: #f8f9fa; border: 1px solid #e0e0e0; border-radius: 6px; padding: 16px; margin: 10px 0; font-family: monospace;">
        #{@pr_string.length.positive? ? @pr_string : '<span style="">There are currently no PRs open for this issue</span>'}
      </div>
    HTML
  end

  private

  def setup
    get_prs
    get_deployments
    set_deployment_strings
    set_pr_string
  end

  def get_prs
    @prs = Gnosis::PullRequest.where(issue_id: @context[:issue].id).to_a
  end

  def get_deployments
    @deployments = @prs.map do |pr|
      Gnosis::PullRequestDeployment.where(pull_request_id: pr['id']).to_a
    end
  end

  def state_icon(state)
    case state
    when 'merged' then '&#x2705;'
    when 'open' then '&#x1F535;'
    when 'draft' then '&#x1F4DD;'
    when 'closed' then '&#x1F534;'
    else '&#x2753;'
    end
  end

  def deployment_status_icon(has_passed)
    has_passed ? '&#x2705;' : '&#x274C;'
  end

  def set_deployment_strings
    @deployments_strings = @deployments.map do |deployment_list|
      deployments_by_branch = {}
      deployment_list.each { |d| deployments_by_branch[d['deploy_branch']] = d }

      branches = deployments_by_branch.keys
      next '' if branches.empty?

      rows = branches.each_with_index.map do |branch, idx|
        deployment = deployments_by_branch[branch]
        connector = idx == branches.length - 1 ? '&#x2514;&#x2500;&#x2500;' : '&#x251C;&#x2500;&#x2500;'
        <<-ROW
          <a href='#{deployment['url']}' target='_blank' id='deployment-#{deployment['id']}' style="display: contents; text-decoration: none; color: inherit;">
            <span>#{connector}</span>
            <span>#{branch}</span>
            <span>#{deployment_status_icon(deployment['has_passed'])}</span>
            <span>#{deployment['ci_date'].strftime('%d.%m.%Y %H:%M UTC')}</span>
          </a>
        ROW
      end.join

      <<-GRID
        <div style="display: grid; grid-template-columns: auto auto auto 1fr; gap: 0 0.8em; align-items: center; margin-left: 20px; line-height: 1.8;">
          #{rows}
        </div>
      GRID
    end
  end

  def set_pr_string
    @pr_string = @prs.each_with_index.map do |pr, index|
      formatted_deployments = @deployments_strings[index]
      <<-LISTOBJECT
        <div style="margin-bottom: 16px;">
          <div>
            <a href='#{pr['url']}' target='_blank' id='pr-#{pr['id']}' style="text-decoration: none; color: inherit; font-weight: bold; font-family: sans-serif; font-size: 14px;">#{pr['title']}</a>
            &nbsp;&nbsp;#{state_icon(pr['state'])} #{pr['state']}
          </div>
          #{formatted_deployments}
        </div>
      LISTOBJECT
    end.join
  end
end
