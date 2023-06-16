# frozen_string_literal: true

require "bcrypt"

module Passwordless
  # Controller for managing Passwordless sessions
  class SessionsController < ApplicationController
    include ControllerHelpers

    # get '/:resource/sign_in'
    #   Assigns an email_field and new Session to be used by new view.
    #   renders sessions/new.html.erb.
    def new
      @email_field = email_field
      @session = Session.new
    end

    # post '/:resource/sign_in'
    #   Creates a new Session record then sends the magic link
    #   redirects to sign in page with generic flash message.
    # @see Mailer#magic_link Mailer#magic_link
    def create
      @resource = find_authenticatable
      session = build_passwordless_session(@resource)

      if session.save
        if Passwordless.after_session_save.arity == 2
          Passwordless.after_session_save.call(session, request)
        else
          Passwordless.after_session_save.call(session)
        end
      end

      flash[:notice] = I18n.t("passwordless.sessions.create.email_sent_if_record_found")
      redirect_back(fallback_location: root_path)
    end

    # get '/:resource/sign_in/:token'
    #   Looks up session record by provided token. Signs in user if a match
    #   is found. Redirects to either the user's original destination
    #   or _root_path_
    # @see ControllerHelpers#sign_in
    # @see ControllerHelpers#save_passwordless_redirect_location!
    def show
      # Make it "slow" on purpose to make brute-force attacks more of a hassle
      redirect_to_options = Passwordless.redirect_to_response_options.dup
      BCrypt::Password.create(params[:token])
      sign_in(passwordless_session)

      redirect_to(passwordless_success_redirect_path, redirect_to_options)
    rescue Errors::TokenAlreadyClaimedError
      flash[:error] = I18n.t(".passwordless.sessions.create.token_claimed")
      redirect_to(passwordless_failure_redirect_path, redirect_to_options)
    rescue Errors::SessionTimedOutError
      flash[:error] = I18n.t(".passwordless.sessions.create.session_expired")
      redirect_to(passwordless_failure_redirect_path, redirect_to_options)
    end

    # match '/:resource/sign_out', via: %i[get delete].
    #   Signs user out. Redirects to root_path
    # @see ControllerHelpers#sign_out
    def destroy
      sign_out(authenticatable_class)
      redirect_to(passwordless_sign_out_redirect_path, Passwordless.redirect_to_response_options.dup)
    end

    protected

    def passwordless_sign_out_redirect_path
      Passwordless.sign_out_redirect_path
    end

    def passwordless_failure_redirect_path
      Passwordless.failure_redirect_path
    end

    def passwordless_query_redirect_path
      query_redirect_uri = URI(params[:destination_path])
      query_redirect_uri.to_s if query_redirect_uri.host.nil? || query_redirect_uri.host == URI(request.url).host
    rescue URI::InvalidURIError, ArgumentError
      nil
    end

    def passwordless_success_redirect_path
      return Passwordless.success_redirect_path unless Passwordless.redirect_back_after_sign_in

      session_redirect_url = reset_passwordless_redirect_location!(authenticatable_class)
      passwordless_query_redirect_path || session_redirect_url || Passwordless.success_redirect_path
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
      email = params[:passwordless][email_field].downcase.strip

      if authenticatable_class.respond_to?(:fetch_resource_for_passwordless)
        authenticatable_class.fetch_resource_for_passwordless(email)
      else
        authenticatable_class.where("lower(#{email_field}) = ?", email).first
      end
    end

    def passwordless_session
      @passwordless_session ||= Session.find_by!(
        authenticatable_type: authenticatable_classname,
        token_digest: Passwordless.digest(params[:token])
      )
    end
  end
end
