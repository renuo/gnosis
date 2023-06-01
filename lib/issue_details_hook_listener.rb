# frozen_string_literal: true

class NewSectionHookListener < Redmine::Hook::ViewListener
  def view_issues_show_description_bottom(context={})
    @context = context
    setup
    <<-HTML
      <hr/>
      <p><strong>Pull Requests</strong></p>
      #{@pr_string.length.positive? ? "<ul>#{@pr_string}</ul>" : 'There are currently no PRs open for this issue'}
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
    @prs = PullRequest.where(issue_id: @context[:issue].id).to_a
  end

  def get_deployments
    @deployments = @prs.map do |pr|
      Deployment.where(pull_request_id: pr['id']).to_a
    end
  end

  def set_deployment_strings
    @deployments_strings = []
    @deployments.each do |deployment_list|
      formatted_deployment_list = []
      deployment_list.each do |deployment|
        formatted_deployment_list << <<-LISTOBJECT
          <li>
            <a href='#{deployment['url']}' target='_blank' id='deployment-#{deployment['id']}'>
              on "#{deployment['deploy_branch']}"
              at #{deployment['ci_date'].strftime('%d.%m.%Y at %I:%M%p UTC')}
              #{deployment['has_passed'] ? '✅' : '❌'}
            </a>
          </li>
        LISTOBJECT
      end
      @deployments_strings << formatted_deployment_list
    end
  end

  def set_pr_string
    @pr_string = @prs.each_with_index.map do |pr, index|
      formatted_deployments_list = @deployments_strings[index].join
      <<-LISTOBJECT
      <li>
        <a href='#{pr['url']}' target='_blank' id='pr-#{pr['id']}'>#{pr['title']} (#{pr['state']})</a> <br/>
        #{formatted_deployments_list.length.positive? ? '<strong>Deployments:</strong>' : ''}
        <ul>
          #{formatted_deployments_list}
        </ul>  
      </li>
      LISTOBJECT
    end.join
  end
end
