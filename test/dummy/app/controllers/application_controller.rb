class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers

  protect_from_forgery with: :exception

  helper_method :current_user

  private

  def current_user
    @current_user ||= authenticate_by_cookie(User)
  end

  def authenticate_user!
    return if current_user
    redirect_to root_path, flash: {error: 'Not worthy!'}
  end
end
