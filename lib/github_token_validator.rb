# frozen_string_literal: true

require 'octokit'

class GithubTokenValidator
  def self.valid?(token)
    return false if token.blank?

    client = Octokit::Client.new(access_token: token)
    client.user
    true
  rescue Octokit::Unauthorized, Octokit::Forbidden
    false
  end
end
