# frozen_string_literal: true

require 'octokit'

class GithubTokenValidator
  def self.valid?(token, skip_api_check: false)
    return false if token.blank?
    return true if skip_api_check

    client = Octokit::Client.new(access_token: token)
    client.user
    true
  rescue Octokit::Unauthorized, Octokit::Forbidden
    false
  end
end
