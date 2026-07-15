class AddUniqueConstraintToPullRequestsUrl < ActiveRecord::Migration[7.2]
  def change
    add_unique_constraint :gnosis_pull_requests, :url, deferable: :deferred
  end
end
