class CreatePullRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :pull_requests do |t|
      t.string :action
      t.string :url
      t.string :title
      t.string :source_branch
      t.string :target_branch
      t.boolean :was_merged, default: false, null: false
      t.references :issue, null: false, foreign_key: true

      t.timestamps
    end
  end
end
