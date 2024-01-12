# frozen_string_literal: true

class LegacyImportService
  def call
    init_client
  end

  def init_client
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
end
