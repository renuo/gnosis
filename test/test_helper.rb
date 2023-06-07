# frozen_string_literal: true

require 'simplecov'

ENV['GOOGLE_CHROME_OPTS_ARGS'] = 'headless,disable-gpu,no-sandbox,disable-dev-shm-usage'
ENV['GITHUB_WEBHOOK_SECRET'] = 'test'
ENV['SEMAPHORE_WEBHOOK_SECRET'] = 'test'

SimpleCov.coverage_dir('plugins/gnosis/coverage')
SimpleCov.start do
  add_filter do |source_file|
    source_file.lines.count < 7
  end

  add_filter do |source_file|
    source_file.filename.exclude?('gnosis/app') && source_file.filename.exclude?('gnosis/lib')
  end
end

SimpleCov.minimum_coverage 100

FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
FactoryBot.find_definitions

# Load the lib folder
Dir[Rails.root.join('plugins/gnosis/lib/**/*.rb')].each { |f| load f }

# Load the Redmine helper
require File.expand_path("#{File.dirname(__FILE__)}/../../../test/test_helper")

# Create seeds
IssueStatus.create!(name: 'To start', default_done_ratio: 0)
Tracker.create!(name: 'Feature', default_status: IssueStatus.first)
IssuePriority.create!(name: 'Normal', is_default: true)

User.create!(
  login: 'admin',
  mail: 'admin@example.com',
  password: '12345678',
  password_confirmation: '12345678',
  admin: true,
  firstname: 'firstname',
  lastname: 'lastname',
  status: Principal::STATUS_ACTIVE
)

name = 'SomeProject'
Project.create!(name: name, identifier: name.downcase, is_public: false, description: '…', issues: [
                  Issue.new(subject: 'some subject', description: '…', tracker: Tracker.first, author: User.first,
                            status: IssueStatus.first, priority: IssuePriority.first),
                  Issue.new(subject: 'some other subject', description: '…', tracker: Tracker.first, author: User.first,
                            status: IssueStatus.first, priority: IssuePriority.first)
                ])
