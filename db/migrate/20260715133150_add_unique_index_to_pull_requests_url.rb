class AddUniqueIndexToPullRequestsUrl < ActiveRecord::Migration[7.2]
  def change
    add_index :gnosis_pull_requests, :url, unique: true
  end
end
