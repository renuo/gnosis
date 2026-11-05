# frozen_string_literal: true

module Gnosis
  class DeploymentCommit < ApplicationRecord
    belongs_to :deployment, inverse_of: :commits

    def url
      "https://github.com/#{deployment.repository}/commit/#{sha}"
    end

    def short_sha
      sha.first(7)
    end
  end
end
