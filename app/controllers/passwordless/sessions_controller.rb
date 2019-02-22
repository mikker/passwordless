# frozen_string_literal: true

require "bcrypt"

module Passwordless
  # Controller for managing Passwordless sessions
  class SessionsController < ApplicationController
    # Raise this exception when a session is expired.
    class SessionTimedOutError < StandardError; end

    include ControllerHelpers

    # get '/sign_in'
    #   Assigns an email_field and new Session to be used by new view.
    #   renders sessions/new.html.erb.
    def new
      @email_field = email_field
      @session = Session.new
    end

    # post '/sign_in'
    #   Creates a new Session record then sends the magic link
    #   renders sessions/create.html.erb.
    # @see Mailer#magic_link Mailer#magic_link
    def create
      session = build_passwordless_session(find_authenticatable)

      if session.save
        Passwordless.after_session_save.call(session)
      end

      render
    end

    # get '/sign_in/:token'
    #   Looks up session record by provided token. Signs in user if a match
    #   is found. Redirects to either the user's original destination
    #   or _root_path_
    # @see ControllerHelpers#sign_in
    # @see ControllerHelpers#save_passwordless_redirect_location!
    def show
      # Make it "slow" on purpose to make brute-force attacks more of a hassle
      BCrypt::Password.create(params[:token])

      session = find_session
      raise SessionTimedOutError if session.timed_out?

      sign_in session.authenticatable

      redirect_enabled = Passwordless.redirect_back_after_sign_in
      destination = reset_passwordless_redirect_location!(User)

      if redirect_enabled && destination
        redirect_to destination
      else
        redirect_to main_app.root_path
      end
    rescue SessionTimedOutError
      flash[:error] = I18n.t(".passwordless.sessions.create.session_expired")
      redirect_to main_app.root_path
    end

    # match '/sign_out', via: %i[get delete].
    #   Signs user out. Redirects to root_path
    # @see ControllerHelpers#sign_out
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

    def email_field
      authenticatable_class.passwordless_email_field
    end

    def find_authenticatable
      email = params[:passwordless][email_field].downcase

      if authenticatable_class.respond_to?(:fetch_resource_for_passwordless)
        authenticatable_class.fetch_resource_for_passwordless(email)
      else
        authenticatable_class.where(
          "lower(#{email_field}) = ?", params[:passwordless][email_field].downcase
        ).first
      end
    end

    def find_session
      Session.find_by!(
        authenticatable_type: authenticatable_classname,
        token: params[:token]
      )
    end
  end
end
