# frozen_string_literal: true

module Gnosis
  # A GitHub repository as `owner/name`, downcased: Semaphore and GitHub don't agree on case.
  module RepositorySlug
    GITHUB_URL = %r{github\.com/([^/]+/[^/]+)}i.freeze

    def self.normalize(slug)
      slug.to_s.downcase.presence
    end

    def self.from_url(url)
      normalize(url.to_s[GITHUB_URL, 1])
    end
  end
end
