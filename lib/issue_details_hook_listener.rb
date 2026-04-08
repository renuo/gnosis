# frozen_string_literal: true

class IssueDetailsHookListener < Redmine::Hook::ViewListener
  def view_issues_show_description_bottom(context={})
    return '' unless User.current.allowed_to?(:view_list, nil, :global => true)

    @context = context
    setup
    <<-HTML
      <style>
        .gnosis-pr-container {
          background: rgba(0, 0, 0, 0.03);
          border: 1px solid rgba(0, 0, 0, 0.1);
          padding: 1rem;
          margin: 0.625rem 0;
          font-family: monospace;
        }
        .gnosis-pr-entry {
          margin-bottom: 1rem;
        }
        .gnosis-pr-link {
          color: inherit;
          font-weight: bold;
        }
        .gnosis-pr-state {
          margin-left: 0.5rem;
        }
        .gnosis-deploy-grid {
          display: grid;
          grid-template-columns: auto auto auto 1fr;
          gap: 0 0.8em;
          align-items: center;
          line-height: 1.8;
        }
        .gnosis-deploy-link {
          display: contents;
          color: inherit;
        }
      </style>
      <hr/>
      <strong>Pull Requests</strong>

      <div class="gnosis-pr-container">
        #{@pr_string.length.positive? ? @pr_string : '<span>There are currently no PRs open for this issue</span>'}
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
    when 'merged' then '🟣'
    when 'open' then '🟢'
    when 'draft' then '⚫'
    when 'closed' then '🔴'
    else '❓'
    end
  end

  def deployment_status_icon(has_passed)
    has_passed ? '✅' : '❌'
  end

  def format_deployment_time(time)
    user_zone = User.current.time_zone
    local_time = user_zone ? time.in_time_zone(user_zone) : time.utc
    local_time.strftime('%d.%m.%Y %H:%M')
  end

  def set_deployment_strings
    @deployments_strings = @deployments.map do |deployment_list|
      deployments_by_branch = {}
      deployment_list.each { |deployment| deployments_by_branch[deployment['deploy_branch']] = deployment }

      branches = deployments_by_branch.keys
      next '' if branches.empty?

      rows = branches.each_with_index.map do |branch, idx|
        deployment = deployments_by_branch[branch]
        connector = idx == branches.length - 1 ? '└──' : '├──'
        <<-ROW
          <a href='#{deployment['url']}' target='_blank' id='deployment-#{deployment['id']}' class="gnosis-deploy-link">
            <span>#{connector}</span>
            <span>#{branch}</span>
            <span>#{deployment_status_icon(deployment['has_passed'])}</span>
            <span>#{format_deployment_time(deployment['ci_date'])}</span>
          </a>
        ROW
      end.join

      <<-GRID
        <div class="gnosis-deploy-grid">
          #{rows}
        </div>
      GRID
    end
  end

  def set_pr_string
    @pr_string = @prs.each_with_index.map do |pr, index|
      formatted_deployments = @deployments_strings[index]
      <<-LISTOBJECT
        <div class="gnosis-pr-entry">
          <div>
            <a href='#{pr['url']}' target='_blank' id='pr-#{pr['id']}' class="gnosis-pr-link">#{pr['title']}</a>
            <span class="gnosis-pr-state">#{state_icon(pr['state'])} #{pr['state']}</span>
          </div>
          #{formatted_deployments}
        </div>
      LISTOBJECT
    end.join
  end
end
