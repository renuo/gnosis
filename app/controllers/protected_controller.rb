class ProtectedController < ApplicationController
  before_action :set_current_user
  before_action :set_current_timer_session
  before_action :permission_manager
  before_action :verify_permission!
  skip_before_action :verify_authenticity_token

  helper_method :offset_for_time_zone

  def verify_permission!
    return unless User.current
    return if permission_manager.can?(action_name.to_sym, controller_name.to_sym)

    render_403(flash: { error: t('timer_sessions.messages.errors.permission.no_access') })
  end

  def set_current_user
    @current_user = User.current
  end
end
