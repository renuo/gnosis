class AddPipelineFileToGnosisPullRequestDeployments < ActiveRecord::Migration[7.2]
  def change
    add_column :gnosis_pull_request_deployments, :pipeline_file, :string
  end
end
