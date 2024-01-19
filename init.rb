# frozen_string_literal: true

require 'redmine'
require_relative 'lib/issue_details_hook_listener'

def check_env
  ENV['GITHUB_WEBHOOK_SECRET'].present? ||
    ENV['GITHUB_ACCESS_TOKEN'].present? ||
    ENV['SEMAPHORE_WEBHOOK_SECRET'].present?
end

# :nocov:
if !check_env && !Rails.env.test?
  yaml_data = if Rails.root.join('plugins/gnosis/config/application.yml').exist?
                YAML.safe_load(ERB.new(Rails.root.join('plugins/gnosis/config/application.yml').read).result)
              else
                Rails.logger.warn 'application.yml not found'
                YAML.safe_load(ERB.new(Rails.root.join('plugins/gnosis/config/application.example.yml').read).result)
              end
  ENV.merge!(ActiveSupport::HashWithIndifferentAccess.new(yaml_data))
end
# :nocov:

raise 'GITHUB_ACCESS_TOKEN is not set' if ENV['GITHUB_ACCESS_TOKEN'].blank? && !Rails.env.test?

Redmine::Plugin.register :gnosis do
  name 'Gnosis plugin'
  author 'Anes Hodza'
  description 'This Plugin allows you to see the status of issues in a project'
  version '1.0.0'
  url 'https://github.com/aneshodza/gnosis/'
  author_url 'https://www.aneshodza.ch/'

  settings default: { }, partial: 'settings/gnosis_settings'

  project_module :gnosis do
    permission :sync_pull_requests, {
      sync: %i[sync_pull_requests]
    }, require: :loggedin
  end
end
