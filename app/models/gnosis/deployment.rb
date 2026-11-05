# frozen_string_literal: true

module Gnosis
  # One CI deploy run, recorded whether or not any of its changes belong to a ticket.
  class Deployment < ApplicationRecord
    has_many :commits, -> { order(:id) }, class_name: 'Gnosis::DeploymentCommit', inverse_of: :deployment,
                                          dependent: :delete_all

    # A project's deployments are those of the repositories its tickets have pull requests in.
    scope :for_project, lambda { |project|
      repositories = PullRequest.joins(:issue)
                                .where(issues: { project_id: project.id })
                                .where.not(repository: nil)
                                .select(:repository)
      where(repository: repositories)
    }

    def self.record(url:, branch:, repository:, has_passed:, ci_date:)
      deployment = find_or_initialize_by(url: url, deploy_branch: branch)
      deployment.update!(repository: RepositorySlug.normalize(repository), has_passed: has_passed, ci_date: ci_date)
      deployment
    end

    def record_commits(commits)
      known = self.commits.pluck(:sha)
      commits.each do |sha, message|
        next if known.include?(sha)

        self.commits.create!(sha: sha, message: message.to_s.lines.first.to_s.strip.truncate(255))
      end
    end
  end
end
