# frozen_string_literal: true

# Deployments used to exist only as a side effect of a pull request with a ticket, so CI
# runs without one (depfu, direct pushes to main) were never recorded. This adds a record
# per CI run, the commits it shipped, and the repository of each pull request, which is
# how a deployment without a ticket is attributed to a project.
class CreateGnosisDeployments < ActiveRecord::Migration[7.2]
  GITHUB_REPOSITORY = %r{github\.com/([^/]+/[^/]+)}i.freeze

  class MigrationPullRequest < ActiveRecord::Base
    self.table_name = 'gnosis_pull_requests'
    self.record_timestamps = false
  end

  class MigrationPullRequestDeployment < ActiveRecord::Base
    self.table_name = 'gnosis_pull_request_deployments'
  end

  class MigrationDeployment < ActiveRecord::Base
    self.table_name = 'gnosis_deployments'
  end

  def up
    add_column :gnosis_pull_requests, :repository, :string
    add_index :gnosis_pull_requests, :repository

    create_table :gnosis_deployments do |t|
      t.string :url, null: false
      t.string :repository
      t.string :deploy_branch, null: false
      t.boolean :has_passed, default: false, null: false
      t.datetime :ci_date

      t.timestamps
    end
    add_index :gnosis_deployments, %i[url deploy_branch], unique: true
    add_index :gnosis_deployments, %i[repository deploy_branch ci_date]

    create_table :gnosis_deployment_commits do |t|
      t.references :deployment, null: false, foreign_key: { to_table: :gnosis_deployments, on_delete: :cascade }
      t.string :sha, null: false
      t.string :message

      t.timestamps
    end
    add_index :gnosis_deployment_commits, %i[deployment_id sha], unique: true

    backfill
  end

  def down
    drop_table :gnosis_deployment_commits
    drop_table :gnosis_deployments
    remove_index :gnosis_pull_requests, :repository
    remove_column :gnosis_pull_requests, :repository
  end

  private

  def backfill
    MigrationPullRequest.reset_column_information
    repositories = {}
    MigrationPullRequest.find_each do |pull_request|
      repository = pull_request.url.to_s[GITHUB_REPOSITORY, 1]&.downcase
      repositories[pull_request.id] = repository
      pull_request.update!(repository: repository) if repository
    end

    # Every pull request of a CI run shares its url; the latest row represents the run.
    runs = MigrationPullRequestDeployment.where.not(url: [nil, '']).where.not(deploy_branch: [nil, ''])
                                         .order(:ci_date, :id)
                                         .group_by { |pr_deployment| [pr_deployment.url, pr_deployment.deploy_branch] }
                                         .values.map(&:last)

    runs.each do |run|
      MigrationDeployment.create!(url: run.url, deploy_branch: run.deploy_branch, has_passed: run.has_passed,
                                  ci_date: run.ci_date, repository: repositories[run.pull_request_id])
    end
  end
end
