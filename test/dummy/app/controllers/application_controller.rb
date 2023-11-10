# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers

  protect_from_forgery with: :exception

  helper_method :current_user, :current_admin

  private

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def current_admin
    @current_admin ||= authenticate_by_session(Admin)
  end

  def authenticate_user!
    return if current_user

    save_passwordless_redirect_location!(User)

    redirect_to(root_path, flash: {error: "Not worthy!"})
  end
end
