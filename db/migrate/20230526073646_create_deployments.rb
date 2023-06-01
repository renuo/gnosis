class CreateDeployments < ActiveRecord::Migration[6.1]
  def change
    create_table :deployments do |t|
      t.string :deploy_branch
      t.string :url
      t.boolean :has_passed, default: false, null: false
      t.references :pull_request, null: false, foreign_key: true
      t.datetime :ci_date

      t.timestamps
    end
  end
end
