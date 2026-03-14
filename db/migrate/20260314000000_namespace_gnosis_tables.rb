# frozen_string_literal: true

class NamespaceGnosisTables < ActiveRecord::Migration[6.1]
  def change
    rename_table :pull_requests, :gnosis_pull_requests
    rename_table :pull_request_deployments, :gnosis_pull_request_deployments
  end
end
