# frozen_string_literal: true

module Gnosis
  # Performs the release the way `renuo release` does, but through the GitHub API: bump the version in the
  # selected files on develop, merge develop into the default branch, then tag that merge.
  class ReleasePerformer
    Result = Struct.new(:version, :tag_url, :bumped_files, keyword_init: true)

    class Error < StandardError; end

    BLOB_MODE = '100644'

    def initialize(repository, version:, previous_version:, version_file_paths: [],
                   client: GithubClient.build)
      @repository = repository
      @version = version
      @previous_version = previous_version
      @version_file_paths = version_file_paths
      @client = client
    end

    def call
      raise Error, "Tag #{@version} already exists." if tag_exists?

      bumped_files = bump_version
      sha = merge_develop_into_main
      create_tag(sha)

      Result.new(version: @version.to_s, tag_url: @repository.tag_url(@version.to_s), bumped_files: bumped_files)
    rescue Octokit::Error => e
      raise Error, github_message(e)
    end

    private

    def full_name
      @repository.full_name
    end

    def develop_branch
      ReleasePreview::DEVELOP_BRANCH
    end

    def main_branch
      ReleasePreview::MAIN_BRANCH
    end

    def tag_exists?
      @client.ref(full_name, "tags/#{@version}")
      true
    rescue Octokit::NotFound
      false
    end

    # One "Bump version" commit for every file, mirroring the CLI's single commit.
    def bump_version
      return [] if @version_file_paths.empty?

      parent_sha = @client.ref(full_name, "heads/#{develop_branch}").object.sha
      entries = @version_file_paths.filter_map { |path| tree_entry_for(path) }
      return [] if entries.empty?

      tree = @client.create_tree(full_name, entries, base_tree: @client.commit(full_name, parent_sha).commit.tree.sha)
      commit = @client.create_commit(full_name, 'Bump version', tree.sha, parent_sha)
      @client.update_ref(full_name, "heads/#{develop_branch}", commit.sha)

      entries.pluck(:path)
    end

    def tree_entry_for(path)
      file = @client.contents(full_name, path: path, ref: develop_branch)
      content = Base64.decode64(file.content).force_encoding(Encoding::UTF_8)
      bumped = content.gsub(@previous_version.to_s, @version.to_s)
      return if bumped == content

      { path: path, mode: BLOB_MODE, type: 'blob', sha: @client.create_blob(full_name, bumped) }
    end

    def merge_develop_into_main
      merge = @client.merge(full_name, main_branch, develop_branch,
                            commit_message: "Merge branch '#{develop_branch}' for release #{@version}")

      # GitHub answers with no content when there is nothing to merge; the branch head is then the release point.
      merge&.sha || @client.ref(full_name, "heads/#{main_branch}").object.sha
    end

    def create_tag(sha)
      tag = @client.create_tag(full_name, @version.to_s, "Release with version: #{@version}", sha, 'commit',
                               User.current.name, User.current.mail.to_s, Time.current.iso8601)
      @client.create_ref(full_name, "refs/tags/#{@version}", tag.sha)
    end

    def github_message(error)
      case error
      when Octokit::Conflict then "#{develop_branch} cannot be merged into #{main_branch} without conflicts."
      when Octokit::NotFound then "#{full_name} or one of its branches could not be found on GitHub."
      else "GitHub rejected the release: #{error.message}"
      end
    end
  end
end
