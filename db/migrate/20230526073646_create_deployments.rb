class CreateDeployments < ActiveRecord::Migration[6.1]
  def change
    create_table :pull_request_deployments do |t|
      t.string :deploy_branch
      t.string :url
      t.boolean :has_passed, default: false, null: false
      t.references :pull_request, null: false
      t.datetime :ci_date

      t.timestamps
    end
  end
end
