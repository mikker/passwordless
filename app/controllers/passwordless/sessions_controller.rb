# frozen_string_literal: true

require "bcrypt"

module Passwordless
  # Controller for managing Passwordless sessions
  class SessionsController < ApplicationController
    include ControllerHelpers

    helper_method :email_field

    # get '/:resource/sign_in'
    #   Assigns an email_field and new Session to be used by new view.
    #   renders sessions/new.html.erb.
    def new
      @session = Session.new
    end

    # post '/:resource/sign_in'
    #   Creates a new Session record then sends the magic link
    #   redirects to sign in page with generic flash message.
    def create
      @resource = find_authenticatable
      @session = build_passwordless_session(@resource)

      if @session.save
        if Passwordless.config.after_session_save.arity == 2
          Passwordless.config.after_session_save.call(@session, request)
        else
          Passwordless.config.after_session_save.call(@session)
        end

        redirect_to(
          url_for(id: @session.id, action: "show"),
          flash: {notice: I18n.t("passwordless.sessions.create.email_sent_if_record_found")}
        )
      else
        render(:new, status: :unprocessable_entity)
      end
    end

    # get "/:resource/sign_in/:id"
    #   Shows the form for confirming a Session record.
    #   renders sessions/show.html.erb.
    def show
      @session = find_session
    end

    # patch "/:resource/sign_in/:id"
    #   User submits the form for confirming a Session record.
    #   Looks up session record by provided token. Signs in user if a match
    #   is found. Redirects to either the user's original destination
    #   or _Passwordless.config.success_redirect_path_.
    #
    # @see ControllerHelpers#sign_in
    # @see ControllerHelpers#save_passwordless_redirect_location!
    def update
      @session = find_session

      artificially_slow_down_brute_force_attacks(passwordless_session_params[:token])

      authenticate_and_sign_in(@session, passwordless_session_params[:token])
    end

    # get "/:resource/sign_in/:id/:token"
    #   User visits the link sent to them via email.
    #   Looks up session record by provided token. Signs in user if a match
    #   is found. Redirects to either the user's original destination
    #   or _Passwordless.config.success_redirect_path_.
    #
    # @see ControllerHelpers#sign_in
    # @see ControllerHelpers#save_passwordless_redirect_location!
    def confirm
      # Some email clients will visit links in emails to check if they are
      # safe. We don't want to sign in the user in that case.
      return head(:ok) if request.head?

      @session = find_session

      artificially_slow_down_brute_force_attacks(params[:token])

      authenticate_and_sign_in(@session, params[:token])
    end

    # match '/:resource/sign_out', via: %i[get delete].
    #   Signs user out. Redirects to root_path
    # @see ControllerHelpers#sign_out
    def destroy
      sign_out(authenticatable_class)
      redirect_to(passwordless_sign_out_redirect_path, Passwordless.config.redirect_to_response_options.dup)
    end

    protected

    def passwordless_sign_out_redirect_path
      Passwordless.config.sign_out_redirect_path
    end

    def passwordless_failure_redirect_path
      Passwordless.config.failure_redirect_path
    end

    def passwordless_query_redirect_path
      query_redirect_uri = URI(params[:destination_path])
      query_redirect_uri.to_s if query_redirect_uri.host.nil? || query_redirect_uri.host == URI(request.url).host
    rescue URI::InvalidURIError, ArgumentError
      nil
    end

    def passwordless_success_redirect_path
      return Passwordless.config.success_redirect_path unless Passwordless.config.redirect_back_after_sign_in

      session_redirect_url = reset_passwordless_redirect_location!(authenticatable_class)
      passwordless_query_redirect_path || session_redirect_url || Passwordless.config.success_redirect_path
    end

    private

    def artificially_slow_down_brute_force_attacks(token)
      # Make it "slow" on purpose to make brute-force attacks more of a hassle
      BCrypt::Password.create(token)
    end

    def authenticate_and_sign_in(session, token)
      if session.authenticate(token)
        sign_in(session)
        redirect_to(passwordless_success_redirect_path, redirect_to_options)
      else
        flash[:error] = I18n.t("passwordless.sessions.errors.invalid_token")
        render(status: :forbidden, action: "show")
      end

    rescue Errors::TokenAlreadyClaimedError
      flash[:error] = I18n.t("passwordless.sessions.errors.token_claimed")
      redirect_to(passwordless_failure_redirect_path, **redirect_to_options)
    rescue Errors::SessionTimedOutError
      flash[:error] = I18n.t("passwordless.sessions.errors.session_expired")
      redirect_to(passwordless_failure_redirect_path, **redirect_to_options)
    end

    def authenticatable
      params.fetch(:authenticatable)
    end

    def authenticatable_type
      authenticatable.to_s.camelize
    end

    def authenticatable_class
      authenticatable_type.constantize
    end

    def find_session
      Session.find_by!(id: params[:id], authenticatable_type: authenticatable_type)
    end

    def find_authenticatable
      email = passwordless_session_params[email_field].downcase.strip

      if authenticatable_class.respond_to?(:fetch_resource_for_passwordless)
        authenticatable_class.fetch_resource_for_passwordless(email)
      else
        authenticatable_class.where("lower(#{email_field}) = ?", email).first
      end
    end

    def email_field
      authenticatable_class.passwordless_email_field
    rescue NoMethodError => e
      raise(
        MissingEmailFieldError,
        <<~MSG
          undefined method `passwordless_email_field' for #{authenticatable_type}

                  Remember to add something like `passwordless_with :email` to you model
        MSG
          .strip_heredoc,
        caller[1..-1]
      )
    end

    def redirect_to_options
      @redirect_to_options ||= (Passwordless.config.redirect_to_response_options.dup || {})
    end

    def passwordless_session
      @passwordless_session ||= Session.find_by!(
        id: params[:id],
        authenticatable_type: authenticatable_type
      )
    end

    def passwordless_session_params
      params.require(:passwordless).permit(:token, authenticatable_class.passwordless_email_field)
    end
  end
end
