# frozen_string_literal: true

class AddGithubUpdatedAtToPullRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :gnosis_pull_requests, :github_updated_at, :datetime
  end
end
