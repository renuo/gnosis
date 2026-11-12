class ClearTestMergeCommitShasOfGnosisPullRequests < ActiveRecord::Migration[7.2]
  def up
    execute 'UPDATE gnosis_pull_requests SET merge_commit_sha = NULL WHERE NOT was_merged'
  end
end
