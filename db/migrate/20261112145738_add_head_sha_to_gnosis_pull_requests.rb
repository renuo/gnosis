class AddHeadShaToGnosisPullRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :gnosis_pull_requests, :head_sha, :string
  end
end
