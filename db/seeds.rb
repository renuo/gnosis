# frozen_string_literal: true

# Development data for the Redmine that bin/setup bootstraps: a login, a project with
# tickets and pull requests, and deployments for the deployments page. Idempotent, so
# re-running bin/setup refreshes the same records instead of piling up new ones.

abort "Refusing to seed the #{Rails.env} database, development only." unless Rails.env.development?

LOGIN = 'developer'
PASSWORD = 'gnosisdev'

Redmine::DefaultData::Loader.load('en') if Redmine::DefaultData::Loader.no_data?

role = Role.givable.find_by(name: 'Manager') || Role.givable.first!
role.add_permission!(:view_list, :view_deployments, :sync_pull_requests)

user = User.find_or_initialize_by(login: LOGIN)
user.attributes = { firstname: 'Deve', lastname: 'Loper', mail: 'developer@example.net',
                    language: 'en', status: User::STATUS_ACTIVE }
user.password = user.password_confirmation = PASSWORD
user.save!

project = Project.find_or_initialize_by(identifier: 'gnosis-demo')
project.attributes = { name: 'Gnosis Demo', description: 'Playground for the Gnosis plugin.',
                       is_public: false }
project.save!
project.enabled_module_names |= %w[issue_tracking gnosis]
Member.find_or_create_by!(project: project, user: user) { |member| member.roles = [role] }

tracker = project.trackers.first || Tracker.first!
status = tracker.default_status || IssueStatus.first!
priority = IssuePriority.default || IssuePriority.first!

def issue!(project, attributes, defaults)
  issue = Issue.find_or_initialize_by(project: project, subject: attributes[:subject])
  issue.attributes = defaults.merge(description: attributes[:description])
  issue.save!
  issue
end

TICKETS = [
  { subject: 'Improve the setup script',
    description: 'bin/setup should bootstrap a Redmine when the plugin is checked out standalone.' },
  { subject: 'Fix stale webhook overwrites',
    description: 'Out-of-order GitHub webhooks must not overwrite a newer pull request state.' },
  { subject: 'Add a deployments page',
    description: 'List the main-branch deployments of a project, grouped per CI run.' }
].freeze

issues = TICKETS.map do |ticket|
  issue!(project, ticket, tracker: tracker, author: user, assigned_to: user,
                          status: status, priority: priority)
end

# Two of these share a main deployment, which is what a CI run over several merged pull
# requests looks like on the deployments page.
MAIN_DEPLOYMENT_URL = 'https://renuo.semaphoreci.com/workflows/9f3c1a2b-main'

pull_requests = [
  { issue: issues[0], number: 51, title: 'Make the plugin developable without a Redmine checkout around it',
    branch: 'feature/%<id>d-improve-setup', state: 'merged', merged: true,
    deployments: [{ branch: 'main', url: MAIN_DEPLOYMENT_URL, passed: true, days_ago: 1 },
                  { branch: 'staging', url: 'https://renuo.semaphoreci.com/workflows/3ac9e01d-staging',
                    passed: true, days_ago: 2 }] },
  { issue: issues[1], number: 49, title: 'Fix stale webhook overwrites',
    branch: 'fix/%<id>d-stale-webhooks', state: 'merged', merged: true,
    deployments: [{ branch: 'main', url: MAIN_DEPLOYMENT_URL, passed: true, days_ago: 1 }] },
  { issue: issues[2], number: 53, title: 'Add a deployments page',
    branch: 'feature/%<id>d-deployments-page', state: 'open', merged: false,
    deployments: [{ branch: 'staging', url: 'https://renuo.semaphoreci.com/workflows/7bd42f88-staging',
                    passed: false, days_ago: 0 }] },
  { issue: issues[2], number: 54, title: 'Paginate the deployments page',
    branch: 'feature/%<id>d-deployments-pagination', state: 'draft', merged: false, deployments: [] },
  { issue: issues[1], number: 42, title: 'Drop webhooks with an unknown ticket number',
    branch: 'fix/%<id>d-unknown-ticket', state: 'closed', merged: false, deployments: [] }
].map do |attributes|
  pull_request = Gnosis::PullRequest.find_or_initialize_by(
    url: "https://github.com/renuo/gnosis/pull/#{attributes[:number]}"
  )
  pull_request.update!(issue: attributes[:issue],
                       title: attributes[:title],
                       state: attributes[:state],
                       source_branch: sprintf(attributes[:branch], id: attributes[:issue].id),
                       target_branch: 'main',
                       was_merged: attributes[:merged],
                       merge_commit_sha: attributes[:merged] ? SecureRandom.hex(20) : nil,
                       github_updated_at: Time.zone.now)

  attributes[:deployments].each do |deployment|
    Gnosis::PullRequestDeployment.auto_create_or_update(deployment[:branch], pull_request.id, deployment[:url],
                                                        deployment[:passed],
                                                        deployment[:days_ago].days.ago.iso8601)
  end

  pull_request
end

puts <<~SUMMARY
  Seeded #{issues.size} tickets, #{pull_requests.size} pull requests and
  #{Gnosis::PullRequestDeployment.count} deployments in project "#{project.name}".
  Log in as #{LOGIN} / #{PASSWORD} (or admin / admin) and open /projects/#{project.identifier}/issues.
SUMMARY
