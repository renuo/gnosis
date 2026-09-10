# frozen_string_literal: true

module Gnosis
  class ReleasesController < ::ApplicationController
    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_repository
    before_action :load_preview

    def new
      @update_type = ReleaseVersion::UPDATE_TYPES.first
      @selected_version_files = offered_version_files
    end

    def create
      @update_type = params[:update_type]
      @selected_version_files = offered_version_files & Array(params[:version_files])
      error = validation_error
      return render_form(error) if error

      perform
    end

    def current_menu_item
      :gnosis_deployments
    end

    private

    def find_repository
      @repository = GithubRepository.for(@project)
      return if @repository

      back_to_deployments error: l(:error_gnosis_no_repository, field: GithubRepository::CUSTOM_FIELD_NAME)
    end

    def load_preview
      @preview = ReleasePreview.new(@repository).load!
      return if @preview.releasable?

      back_to_deployments error: l(:error_gnosis_no_develop_branch, branch: @preview.develop_branch)
    rescue Octokit::Error => e
      back_to_deployments error: l(:error_gnosis_github_unreachable, message: e.message)
    end

    def validation_error
      return l(:error_gnosis_invalid_update_type) if ReleaseVersion::UPDATE_TYPES.exclude?(@update_type)
      return l(:error_gnosis_invalid_version) if requested_version.nil?
      return l(:error_gnosis_changes_not_reviewed) if params[:reviewed] != '1'
      return l(:error_gnosis_friday_not_confirmed) if late_friday? && params[:friday_confirmed] != '1'

      nil
    end

    def requested_version
      @requested_version ||= if @update_type == 'custom'
                               ReleaseVersion.parse(params[:custom_version])
                                             &.with_prefix_of(@preview.current_version)
                             else
                               @preview.current_version.bump(@update_type)
                             end
    end

    def perform
      result = ReleasePerformer.new(@repository,
                                    version: requested_version,
                                    previous_version: @preview.current_version,
                                    version_file_paths: @selected_version_files).call

      back_to_deployments notice: l(:notice_gnosis_release_created, version: result.version,
                                                                    repository: @repository.full_name)
    rescue ReleasePerformer::Error => e
      render_form(e.message)
    end

    def offered_version_files
      @preview.version_files.map(&:path)
    end

    def render_form(error)
      flash.now[:error] = error
      render :new, status: :unprocessable_entity
    end

    def back_to_deployments(error: nil, notice: nil)
      flash[:error] = error if error
      flash[:notice] = notice if notice
      redirect_to project_gnosis_deployments_path(@project)
    end

    # The CLI asks one more time when you deploy late on a Friday. So do we.
    def late_friday?
      Time.current.friday? && Time.current.hour >= 16
    end
    helper_method :late_friday?
  end
end
