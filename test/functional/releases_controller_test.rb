# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/github_stubs'

class ReleasesControllerTest < ActionController::TestCase
  include GithubStubs

  VERSION_FILE = "module Foo\n  VERSION = '1.4.2'\nend\n"
  VERSION_PATH = 'lib/foo/version.rb'

  def setup
    @controller = Gnosis::ReleasesController.new
    @project = Project.first
    @project.enabled_modules.find_or_create_by!(name: 'gnosis')
    @request.session[:user_id] = 1 # admin

    @custom_field = ProjectCustomField.find_or_create_by!(name: Gnosis::GithubRepository::CUSTOM_FIELD_NAME) do |field|
      field.field_format = 'string'
    end
    configure_repository(REPOSITORY)

    @client = mock('octokit')
    Gnosis::GithubClient.stubs(:build).returns(@client)
    stub_preview
  end

  def test_new_shows_the_changes_the_versions_and_the_version_files
    get :new, params: { project_id: @project.identifier }

    assert_response :success
    assert_select 'a[href=?]', "https://github.com/#{REPOSITORY}/compare/main...develop"
    assert_select '.release-commits td', text: /Fix invoice rounding/
    assert_select 'input#update_type_patch[checked]'
    assert_select '.release-next-version', text: '1.4.3'
    assert_select '.release-next-version', text: '1.5.0'
    assert_select '.release-next-version', text: '2.0.0'
    assert_select 'input[name=?][value=?][checked]', 'version_files[]', VERSION_PATH
    assert_select '.release-version-file-lines', text: /VERSION = '1\.4\.2'/
  end

  def test_new_redirects_when_the_project_has_no_repository
    configure_repository('')

    get :new, params: { project_id: @project.identifier }

    assert_redirected_to project_gnosis_deployments_path(@project)
    assert_match Gnosis::GithubRepository::CUSTOM_FIELD_NAME, flash[:error]
  end

  def test_new_redirects_when_the_repository_has_no_develop_branch
    @client.stubs(:ref).with(REPOSITORY, 'heads/develop').raises(Octokit::NotFound.new)

    get :new, params: { project_id: @project.identifier }

    assert_redirected_to project_gnosis_deployments_path(@project)
    assert_equal 'This repository has no develop branch to release from.', flash[:error]
  end

  def test_new_redirects_when_github_is_unreachable
    failure = Octokit::TooManyRequests.new
    failure.stubs(:message).returns('rate limit exceeded')
    @client.stubs(:ref).raises(failure)

    get :new, params: { project_id: @project.identifier }

    assert_redirected_to project_gnosis_deployments_path(@project)
    assert_match 'rate limit exceeded', flash[:error]
  end

  def test_new_is_denied_without_the_permission
    @request.session[:user_id] = 2
    get :new, params: { project_id: @project.identifier }

    assert_response :forbidden
  end

  def test_create_releases_the_selected_bump
    expect_release('1.5.0', version_file_paths: [VERSION_PATH])

    post :create, params: release_params(update_type: 'minor', version_files: [VERSION_PATH])

    assert_redirected_to project_gnosis_deployments_path(@project)
    assert_equal "Released #{REPOSITORY} as 1.5.0.", flash[:notice]
  end

  def test_create_accepts_a_custom_version
    expect_release('2.5.0')

    post :create, params: release_params(update_type: 'custom', custom_version: '2.5.0')

    assert_redirected_to project_gnosis_deployments_path(@project)
  end

  def test_create_ignores_version_files_that_were_never_offered
    expect_release('1.4.3', version_file_paths: [])

    post :create, params: release_params(version_files: ['config/database.yml'])

    assert_redirected_to project_gnosis_deployments_path(@project)
  end

  def test_create_rejects_an_unknown_update_type
    post :create, params: release_params(update_type: 'gigantic')

    assert_response :unprocessable_entity
    assert_equal 'Choose whether this is a patch, minor, major or custom release.', flash[:error]
  end

  def test_create_rejects_a_malformed_custom_version
    post :create, params: release_params(update_type: 'custom', custom_version: 'next')

    assert_response :unprocessable_entity
    assert_equal 'Enter a custom version in the format X.Y.Z.', flash[:error]
  end

  def test_create_rejects_unreviewed_changes
    post :create, params: release_params(reviewed: '0')

    assert_response :unprocessable_entity
    assert_equal 'Confirm that you reviewed the changes before releasing.', flash[:error]
  end

  def test_create_keeps_the_ticked_version_files_when_it_re_renders
    post :create, params: release_params(reviewed: '0', version_files: [VERSION_PATH])

    assert_response :unprocessable_entity
    assert_select 'input[name=?][value=?][checked]', 'version_files[]', VERSION_PATH
  end

  def test_create_asks_twice_on_a_late_friday
    travel_to Time.zone.local(2026, 8, 21, 17, 0) do
      post :create, params: release_params

      assert_response :unprocessable_entity
      assert_equal 'Confirm the late Friday deployment before releasing.', flash[:error]
      assert_select '.release-friday-warning'
    end
  end

  def test_create_releases_on_a_late_friday_once_confirmed
    travel_to Time.zone.local(2026, 8, 21, 17, 0) do
      expect_release('1.4.3')

      post :create, params: release_params(friday_confirmed: '1')

      assert_redirected_to project_gnosis_deployments_path(@project)
    end
  end

  def test_create_re_renders_when_github_refuses_the_release
    Gnosis::ReleasePerformer.any_instance.stubs(:call)
                            .raises(Gnosis::ReleasePerformer::Error, 'Tag 1.4.3 already exists.')

    post :create, params: release_params

    assert_response :unprocessable_entity
    assert_equal 'Tag 1.4.3 already exists.', flash[:error]
  end

  private

  def release_params(overrides = {})
    { project_id: @project.identifier, update_type: 'patch', reviewed: '1' }.merge(overrides)
  end

  def configure_repository(value)
    @project.custom_field_values = { @custom_field.id => value }
    @project.save!
  end

  def stub_preview
    @client.stubs(:ref).with(REPOSITORY, 'heads/develop').returns(github_ref('develop-sha'))
    @client.stubs(:tags).returns([Tag.new(name: '1.4.2')])
    @client.stubs(:compare).returns(github_comparison)
    @client.stubs(:search_code).returns(SearchResult.new(items: []))
    @client.stubs(:tree).returns(github_tree(VERSION_PATH))
    @client.stubs(:blob).returns(github_blob(VERSION_FILE))
  end

  def expect_release(version, version_file_paths: [])
    result = Gnosis::ReleasePerformer::Result.new(version: version,
                                                  tag_url: "https://github.com/#{REPOSITORY}/releases/tag/#{version}",
                                                  bumped_files: version_file_paths)
    Gnosis::ReleasePerformer.expects(:new).with do |repository, options|
      repository.full_name == REPOSITORY &&
        options[:version].to_s == version &&
        options[:previous_version].to_s == '1.4.2' &&
        options[:version_file_paths] == version_file_paths
    end.returns(stub(call: result))
    result
  end
end
