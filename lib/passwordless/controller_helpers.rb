# frozen_string_literal: true

module Passwordless
  # Helpers to work with Passwordless sessions from controllers
  module ControllerHelpers
    # Returns the {Passwordless::Session} (if set) from the session.
    # @return [Session, nil]
    def find_passwordless_session_for(authenticatable_class)
      Passwordless::Session.find_by(id: session[session_key(authenticatable_class)])
    end

    # Build a new Passwordless::Session from an _authenticatable_ record.
    # Set's `user_agent` and `remote_addr` from Rails' `request`.
    # @param authenticatable [ActiveRecord::Base] Instance of an
    #   authenticatable Rails model
    # @return [Session] the new Session object
    # @see ModelHelpers#passwordless_with
    def build_passwordless_session(authenticatable)
      Session.new.tap do |us|
        us.remote_addr = request.remote_addr
        us.user_agent = request.env["HTTP_USER_AGENT"]
        us.authenticatable = authenticatable
      end
    end

    # Authenticate a record using the session. Looks for a session key corresponding to
    # the _authenticatable_class_. If found try to find it in the database.
    # @param authenticatable_class [ActiveRecord::Base] any Model connected to
    #   passwordless. (e.g - _User_ or _Admin_).
    # @return [ActiveRecord::Base|nil] an instance of Model found by id stored
    #   in cookies.encrypted or nil if nothing is found.
    # @see ModelHelpers#passwordless_with
    def authenticate_by_session(authenticatable_class)
      return unless find_passwordless_session_for(authenticatable_class)&.available?
      find_passwordless_session_for(authenticatable_class).authenticatable
    end

    # Signs in session
    # @param authenticatable [Passwordless::Session] Instance of {Passwordless::Session}
    # to sign in
    # @return [ActiveRecord::Base] the record that is passed in.
    def sign_in(passwordless_session)
      passwordless_session.claim! if Passwordless.restrict_token_reuse

      raise Passwordless::Errors::SessionTimedOutError if passwordless_session.timed_out?

      if defined?(reset_session)
        old_session = session.dup.to_hash
        # allow usage outside controllers
        reset_session
        old_session.each_pair { |k, v| session[k.to_sym] = v }
      end

      key = session_key(passwordless_session.authenticatable_type)
      session[key] = passwordless_session.id

      passwordless_session
    end

    # Signs out user by deleting the session key.
    # @param (see #authenticate_by_session)
    # @return [boolean] Always true
    def sign_out(authenticatable_class)
      session.delete(session_key(authenticatable_class))
      reset_session
      true
    end

    # Saves request.original_url as the redirect location for a
    # passwordless Model.
    # @param (see #authenticate_by_session)
    # @return [String] the redirect url that was just saved.
    def save_passwordless_redirect_location!(authenticatable_class)
      session[redirect_session_key(authenticatable_class)] = request.original_url
    end

    # Resets the redirect_location to root_path by deleting the redirect_url
    # from session.
    # @param (see #authenticate_by_session)
    # @return [String, nil] the redirect url that was just deleted,
    #   or nil if no url found for given Model.
    def reset_passwordless_redirect_location!(authenticatable_class)
      session.delete(redirect_session_key(authenticatable_class))
    end

    def session_key(authenticatable_class)
      :"passwordless_session_id--#{authenticatable_class_parameterized(authenticatable_class)}"
    end

    def redirect_session_key(authenticatable_class)
      :"passwordless_prev_location--#{authenticatable_class_parameterized(authenticatable_class)}"
    end

    private

    def authenticatable_class_parameterized(authenticatable_class)
      if authenticatable_class.is_a?(String)
        authenticatable_class = authenticatable_class.constantize
      end

      authenticatable_class.base_class.to_s.parameterize
    end
  end
end
