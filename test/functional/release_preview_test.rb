# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/github_stubs'

class ReleasePreviewTest < ActiveSupport::TestCase
  include GithubStubs

  VERSION_FILE = "module Foo\n  VERSION = '1.4.2'\nend\n"

  def setup
    @client = mock('octokit')
    @preview = Gnosis::ReleasePreview.new(github_repository, client: @client)
  end

  # develop is the default branch on plenty of Renuo repositories, so it must not decide the release target.
  def test_always_releases_into_main
    stub_repository

    assert_equal 'main', @preview.main_branch
    assert_equal 'develop', @preview.develop_branch
    assert @preview.releasable?
  end

  # Trunk based repositories are simply not releasable from here.
  def test_not_releasable_without_a_develop_branch
    stub_repository(existing: [])

    assert_not @preview.releasable?
    assert_same @preview, @preview.load!
  end

  def test_current_version_is_the_highest_semver_tag
    @client.expects(:tags).with(REPOSITORY).returns([Tag.new(name: '1.9.0'), Tag.new(name: '1.10.0'),
                                                     Tag.new(name: 'nightly')])

    assert_equal '1.10.0', @preview.current_version.to_s
    assert @preview.released_before?
  end

  def test_current_version_falls_back_to_zero_without_tags
    @client.expects(:tags).with(REPOSITORY).returns([])

    assert_equal '0.0.0', @preview.current_version.to_s
    assert_not @preview.released_before?
  end

  def test_version_files_are_skipped_before_the_first_release
    @client.expects(:tags).with(REPOSITORY).returns([])

    assert_empty @preview.version_files
  end

  def test_comparison_lists_the_commits_oldest_first
    stub_repository
    @client.expects(:compare).with(REPOSITORY, 'main', 'develop')
           .returns(github_comparison(commits: [github_commit('newer', 'Second'), github_commit('older', 'First')]))

    assert_equal %w[older newer], @preview.commits.map(&:sha)
    assert_equal 1, @preview.changed_files.size
    assert @preview.changes?
    assert_equal "https://github.com/#{REPOSITORY}/compare/main...develop", @preview.compare_url
  end

  def test_no_changes_to_release
    stub_repository
    @client.expects(:compare).returns(github_comparison(commits: [], files: []))

    assert_not @preview.changes?
  end

  def test_version_files_combine_code_search_and_conventional_paths
    stub_tags
    stub_search('app/models/config.rb')
    stub_tree('app/models/config.rb', 'lib/foo/version.rb', 'app/models/other.rb')
    stub_blob('app/models/config.rb', VERSION_FILE)
    stub_blob('lib/foo/version.rb', VERSION_FILE)

    assert_equal ['app/models/config.rb', 'lib/foo/version.rb'], @preview.version_files.map(&:path)
    assert_equal ["VERSION = '1.4.2'"], @preview.version_files.first.matching_lines
    assert_equal '100644', @preview.version_files.first.mode
  end

  def test_version_files_ignore_candidates_whose_content_does_not_match
    stub_tags
    stub_search('app/models/config.rb')
    stub_tree('app/models/config.rb')
    stub_blob('app/models/config.rb', "module Foo\nend\n")

    assert_empty @preview.version_files
  end

  def test_version_files_ignore_search_hits_that_are_not_ruby_blobs
    stub_tags
    stub_search('README.md')
    stub_tree('app/models/other.rb')

    assert_empty @preview.version_files
  end

  def test_version_files_survive_an_unavailable_code_search
    stub_tags
    @client.expects(:search_code).raises(Octokit::TooManyRequests.new)
    stub_tree('lib/foo/version.rb')
    stub_blob('lib/foo/version.rb', VERSION_FILE)

    assert_equal ['lib/foo/version.rb'], @preview.version_files.map(&:path)
  end

  def test_load_fetches_everything_the_page_needs
    stub_repository
    stub_tags
    @client.expects(:compare).returns(github_comparison)
    stub_search
    stub_tree

    assert_same @preview, @preview.load!
  end

  private

  def stub_repository(existing: %w[develop])
    expectation = @client.stubs(:ref).with(REPOSITORY, 'heads/develop')
    if existing.include?('develop')
      expectation.returns(github_ref('develop-sha'))
    else
      expectation.raises(Octokit::NotFound.new)
    end
  end

  def stub_tags(*names)
    names = ['1.4.2'] if names.empty?
    @client.stubs(:tags).with(REPOSITORY).returns(names.map { |name| Tag.new(name: name) })
  end

  def stub_search(*paths)
    @client.expects(:search_code)
           .returns(SearchResult.new(items: paths.map { |path| SearchItem.new(path: path) }))
  end

  def stub_tree(*paths)
    @client.stubs(:tree).with(REPOSITORY, 'develop', recursive: true).returns(github_tree(*paths))
  end

  def stub_blob(path, content)
    @client.expects(:blob).with(REPOSITORY, "sha-#{path}").returns(github_blob(content))
  end
end
