# frozen_string_literal: true

require 'redmine'
# Zeitwerk autoloads this listener through the plugin directory, which may be a symlink.
# `require_relative` would start loading the file under the resolved path, and its
# `class` line would fire the still-pending autoload, requiring the file again through
# the symlink. Ruby only deduplicates finished loads, so the body would run twice.
# Requiring the same path Zeitwerk uses keeps it at one load.
require File.expand_path('lib/issue_details_hook_listener', File.dirname(__FILE__))

def check_env
  ENV['GITHUB_WEBHOOK_SECRET'].present? ||
    ENV['GITHUB_ACCESS_TOKEN'].present? ||
    ENV['SEMAPHORE_WEBHOOK_SECRET'].present? ||
    ENV['GITHUB_ORGANIZATION_NAME'].present?
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
  version '2.0.0'
  url 'https://github.com/renuo/gnosis/'
  author_url 'https://www.renuo.ch/'

  settings default: { }, partial: 'settings/gnosis_settings'

  project_module :gnosis do
    permission :view_list, {}
    permission :view_deployments, {
      'gnosis/deployments': [:index]
    }
    permission :create_release, {
      'gnosis/releases': %i[new create]
    }, require: :member
  end

  project_module :gnosis do
    permission :sync_pull_requests, {
      'gnosis/sync': %i[sync_pull_requests]
    }, require: :loggedin
  end

  menu :project_menu, :gnosis_deployments, { controller: 'gnosis/deployments', action: 'index' },
       caption: :label_gnosis_deployments, after: :activity, param: :project_id
end
