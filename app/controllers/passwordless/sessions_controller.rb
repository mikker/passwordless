require 'bcrypt'

module Passwordless
  class SessionsController < ApplicationController
    include ControllerHelpers

    helper_method :authenticatable_resource

    def new
      @email_field = authenticatable_class.passwordless_email_field

      @session = Session.new
    end

    def create
      email_field = authenticatable_class.passwordless_email_field
      email = params.require(:passwordless).fetch(email_field).downcase
      authenticatable =
        authenticatable_class.where("lower(#{email_field}) = ?", email).first

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
      # Make it "slow" on purpose to make brute-force attacks more of a hassle
      BCrypt::Password.create(params[:token])

      session = Session.valid.find_by!(
        authenticatable_type: authenticatable_classname,
        token: params[:token]
      )

      sign_in session.authenticatable

      enabled = Passwordless.redirect_back_after_sign_in
      destination = dest = reset_passwordless_redirect_location!(User)

      if enabled && destination
        redirect_to dest
      else
        redirect_to main_app.root_path
      end
    end

    def destroy
      sign_out authenticatable_class
      redirect_to main_app.root_path
    end

    private

    def authenticatable
      params.fetch(:authenticatable)
    end

    def authenticatable_classname
      authenticatable.to_s.camelize
    end

    def authenticatable_class
      authenticatable_classname.constantize
    end

    def authenticatable_resource
      authenticatable.pluralize
    end
  end
end
