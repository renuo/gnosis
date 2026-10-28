# frozen_string_literal: true

module Gnosis
  # Read-only view of what a release would do: which versions are on offer, what develop adds on top of the
  # default branch, and which files carry the current version string.
  class ReleasePreview
    VersionFile = Struct.new(:path, :mode, :matching_lines, keyword_init: true)

    DEVELOP_BRANCH = 'develop'
    MAIN_BRANCH = 'main'
    MAX_VERSION_FILES = 20
    VERSION_FILE_PATTERN = %r{(\A|/)version\.rb\z}.freeze

    attr_reader :repository

    def initialize(repository, client: GithubClient.build(auto_paginate: true))
      @repository = repository
      @client = client
    end

    def develop_branch
      DEVELOP_BRANCH
    end

    # Not the repository's default branch: develop is the default on many Renuo repositories so that pull
    # requests target it, while main is always the branch we release into.
    def main_branch
      MAIN_BRANCH
    end

    # Trunk based repositories have no develop branch and cannot be released from here.
    def releasable?
      return @releasable if defined?(@releasable)

      @releasable = branch_exists?(develop_branch)
    end

    # Fetches everything the confirmation page needs up front, so rendering never talks to GitHub.
    def load!
      return self unless releasable?

      current_version
      comparison
      version_files
      self
    end

    def tag_names
      @tag_names ||= @client.tags(full_name).map(&:name)
    end

    def current_version
      @current_version ||= ReleaseVersion.latest(tag_names) || ReleaseVersion.parse(ReleaseVersion::INITIAL)
    end

    def released_before?
      current_version.to_s != ReleaseVersion::INITIAL
    end

    def comparison
      @comparison ||= @client.compare(full_name, main_branch, develop_branch)
    end

    def commits
      comparison.commits.reverse
    end

    def changed_files
      comparison.files
    end

    def changes?
      commits.any?
    end

    def compare_url
      repository.compare_url(main_branch, develop_branch)
    end

    # Mirrors the CLI's `grep -rl` over *.rb: candidates come from code search and from the conventional
    # version.rb locations, and every candidate is read back so we only ever offer files that really match.
    def version_files
      @version_files ||= if released_before?
                           candidate_paths.first(MAX_VERSION_FILES).filter_map { |path| version_file_for(path) }
                         else
                           []
                         end
    end

    private

    def full_name
      repository.full_name
    end

    def branch_exists?(name)
      @client.ref(full_name, "heads/#{name}")
      true
    rescue Octokit::NotFound
      false
    end

    def candidate_paths
      (searched_paths + conventional_paths).uniq.sort
    end

    def searched_paths
      @client.search_code(%("#{current_version}" repo:#{full_name} language:ruby)).items.map(&:path)
    rescue Octokit::Error
      []
    end

    def conventional_paths
      ruby_blobs.select { |blob| blob.path.match?(VERSION_FILE_PATTERN) }.map(&:path)
    end

    def ruby_blobs
      @ruby_blobs ||= @client.tree(full_name, develop_branch, recursive: true)
                             .tree.select { |blob| blob.type == 'blob' && blob.path.end_with?('.rb') }
    end

    def version_file_for(path)
      blob = ruby_blobs.find { |candidate| candidate.path == path }
      return if blob.nil?

      content = Base64.decode64(@client.blob(full_name, blob.sha).content).force_encoding(Encoding::UTF_8)
      matches = content.lines.grep(/#{Regexp.escape(current_version.to_s)}/).map(&:strip)
      return if matches.empty?

      VersionFile.new(path: path, mode: blob.mode, matching_lines: matches)
    end
  end
end
