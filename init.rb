# frozen_string_literal: true

require 'redmine'
require_relative 'lib/issue_details_hook_listener'

unless Rails.env.test?
  yaml_data
  if File.exist?(Rails.root.join('plugins/gnosis/config/application.yml'))
    yaml_data = YAML.safe_load(ERB.new(Rails.root.join('plugins/gnosis/config/application.yml').read).result)
  else
    Rails.logger.warn 'application.yml not found'
    yaml_data = YAML.safe_load(ERB.new(Rails.root.join('plugins/gnosis/config/application.yml.example').read).result)
  end
  ENV = ActiveSupport::HashWithIndifferentAccess.new(yaml_data)
end

if ENV['GITHUB_ACCESS_TOKEN'].blank? && !Rails.env.test?
  raise 'GITHUB_ACCESS_TOKEN is not set'
elsif ENV['GITHUB_ACCESS_TOKEN'] == 'your_token'
  Rails.logger.warn 'GITHUB_ACCESS_TOKEN is default value'
end

Redmine::Plugin.register :gnosis do
  name 'Gnosis plugin'
  author 'Anes Hodza'
  description 'This Plugin allows you to see the status of issues in a project'
  version '1.0.0'
  url 'https://github.com/aneshodza/gnosis/'
  author_url 'https://www.aneshodza.ch/'
end
