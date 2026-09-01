# frozen_string_literal: true

module Gnosis
  module GithubClient
    def self.build(**options)
      Octokit::Client.new(access_token: ENV.fetch('GITHUB_ACCESS_TOKEN'), **options)
    end
  end
end
