# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/github_stubs'

class ReleasePerformerTest < ActiveSupport::TestCase
  include GithubStubs

  VERSION_FILE = "module Foo\n  VERSION = '1.4.2'\nend\n"
  VERSION_PATH = 'lib/foo/version.rb'

  def setup
    @client = mock('octokit')
  end

  def test_refuses_to_release_an_existing_tag
    @client.expects(:ref).with(REPOSITORY, 'tags/1.5.0').returns(github_ref('whatever'))

    error = assert_raises(Gnosis::ReleasePerformer::Error) { performer.call }
    assert_equal 'Tag 1.5.0 already exists.', error.message
  end

  def test_merges_and_tags_without_touching_any_file
    stub_missing_tag
    @client.expects(:merge)
           .with(REPOSITORY, 'main', 'develop', commit_message: "Merge branch 'develop' for release 1.5.0")
           .returns(Sha.new(sha: 'merge-sha'))
    expect_tag('merge-sha')

    result = performer.call

    assert_equal '1.5.0', result.version
    assert_equal "https://github.com/#{REPOSITORY}/releases/tag/1.5.0", result.tag_url
    assert_empty result.bumped_files
  end

  def test_tags_the_current_head_when_there_is_nothing_to_merge
    stub_missing_tag
    @client.expects(:merge).returns(nil)
    @client.expects(:ref).with(REPOSITORY, 'heads/main').returns(github_ref('main-sha'))
    expect_tag('main-sha')

    assert_equal '1.5.0', performer.call.version
  end

  def test_bumps_the_version_in_the_selected_files_in_a_single_commit
    stub_missing_tag
    @client.expects(:ref).with(REPOSITORY, 'heads/develop').returns(github_ref('develop-sha'))
    @client.expects(:contents).with(REPOSITORY, path: VERSION_PATH, ref: 'develop').returns(github_blob(VERSION_FILE))
    @client.expects(:create_blob).with(REPOSITORY, "module Foo\n  VERSION = '1.5.0'\nend\n").returns('blob-sha')
    @client.expects(:commit).with(REPOSITORY, 'develop-sha')
           .returns(Commit.new(commit: CommitDetail.new(tree: Sha.new(sha: 'tree-sha'))))
    @client.expects(:create_tree)
           .with(REPOSITORY, [{ path: VERSION_PATH, mode: '100644', type: 'blob', sha: 'blob-sha' }],
                 base_tree: 'tree-sha')
           .returns(Sha.new(sha: 'new-tree-sha'))
    @client.expects(:create_commit).with(REPOSITORY, 'Bump version', 'new-tree-sha', 'develop-sha')
           .returns(Sha.new(sha: 'bump-sha'))
    @client.expects(:update_ref).with(REPOSITORY, 'heads/develop', 'bump-sha')
    @client.expects(:merge).returns(Sha.new(sha: 'merge-sha'))
    expect_tag('merge-sha')

    assert_equal [VERSION_PATH], performer(version_file_paths: [VERSION_PATH]).call.bumped_files
  end

  def test_skips_the_bump_commit_when_no_file_actually_changes
    stub_missing_tag
    @client.expects(:ref).with(REPOSITORY, 'heads/develop').returns(github_ref('develop-sha'))
    @client.expects(:contents).returns(github_blob("module Foo\nend\n"))
    @client.expects(:create_tree).never
    @client.expects(:merge).returns(Sha.new(sha: 'merge-sha'))
    expect_tag('merge-sha')

    assert_empty performer(version_file_paths: [VERSION_PATH]).call.bumped_files
  end

  def test_reports_a_merge_conflict
    stub_missing_tag
    @client.expects(:merge).raises(Octokit::Conflict.new)

    error = assert_raises(Gnosis::ReleasePerformer::Error) { performer.call }
    assert_equal 'develop cannot be merged into main without conflicts.', error.message
  end

  def test_reports_a_missing_repository
    stub_missing_tag
    @client.expects(:merge).raises(Octokit::NotFound.new)

    error = assert_raises(Gnosis::ReleasePerformer::Error) { performer.call }
    assert_equal "#{REPOSITORY} or one of its branches could not be found on GitHub.", error.message
  end

  def test_reports_any_other_github_failure
    stub_missing_tag
    failure = Octokit::UnprocessableEntity.new
    failure.stubs(:message).returns('Reference already exists')
    @client.expects(:merge).raises(failure)

    error = assert_raises(Gnosis::ReleasePerformer::Error) { performer.call }
    assert_equal 'GitHub rejected the release: Reference already exists', error.message
  end

  private

  def performer(version_file_paths: [])
    Gnosis::ReleasePerformer.new(github_repository,
                                 version: Gnosis::ReleaseVersion.parse('1.5.0'),
                                 previous_version: Gnosis::ReleaseVersion.parse('1.4.2'),
                                 version_file_paths: version_file_paths,
                                 client: @client)
  end

  def stub_missing_tag
    @client.expects(:ref).with(REPOSITORY, 'tags/1.5.0').raises(Octokit::NotFound.new)
  end

  def expect_tag(sha)
    @client.expects(:create_tag)
           .with(REPOSITORY, '1.5.0', 'Release with version: 1.5.0', sha, 'commit',
                 User.current.name, User.current.mail.to_s, anything)
           .returns(Sha.new(sha: 'tag-sha'))
    @client.expects(:create_ref).with(REPOSITORY, 'refs/tags/1.5.0', 'tag-sha')
  end
end
