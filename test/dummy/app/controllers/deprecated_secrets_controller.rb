# frozen_string_literal: true

class DeprecatedSecretsController < ApplicationController
  before_action :authenticate_user!, except: [:fake_login]

  # Sign in using deprecated cookie implementation
  def fake_login
    key = cookie_name(fake_login_params[:authenticatable_type].constantize)
    cookies.encrypted.permanent[key] = params[:authenticatable_id]
  end

  def index
    render(plain: "shhhh! secrets!")
  end

  private

  def fake_login_params
    params.permit(:authenticatable_id, :authenticatable_type)
  end
end
