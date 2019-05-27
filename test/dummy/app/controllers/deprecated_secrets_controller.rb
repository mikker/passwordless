# frozen_string_literal: true

class DeprecatedSecretsController < ApplicationController
  before_action :authenticate_user!, except: [:fake_login]

  def fake_login
    cookies.encrypted.permanent[cookie_name(fake_login_params[:authenticatable_type].constantize)] = params[:authenticatable_id]
  end

  def index
    render plain: "shhhh! secrets!"
  end

  private

  def fake_login_params
    params.permit(:authenticatable_id, :authenticatable_type)
  end

  def current_user
    @current_user ||= authenticate_by_cookie(User)
  end
end
