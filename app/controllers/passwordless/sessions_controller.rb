module Passwordless
  class SessionsController < ApplicationController
    include ControllerHelpers

    def new
      @email_field = authenticatable_class.passwordless_email_field

      @session = Session.new
    end

    def create
      email_field = authenticatable_class.passwordless_email_field
      authenticatable = authenticatable_class.where(
        "lower(#{email_field}) = ?", params[:passwordless][email_field]
      ).first

      session = Session.new.tap do |us|
        us.remote_addr = request.remote_addr
        us.user_agent = request.env['HTTP_USER_AGENT']
        us.authenticatable = authenticatable
      end

      if session.save
        Mailer.magic_link(session).deliver_now
      end

      render
    end

    def show
      session = Session.valid.find_by!(
        authenticatable_type: authenticatable_classname,
        token: params[:token]
      )

      sign_in! session.authenticatable

      redirect_to main_app.root_path
    end

    def destroy
      sign_out! authenticatable_class
      redirect_to main_app.root_path
    end

    private

    def authenticatable_classname
      params[:authenticatable].to_s.camelize
    end

    def authenticatable_class
      authenticatable_classname.constantize
    end
  end
end
