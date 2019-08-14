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

    # @deprecated Use {ControllerHelpers#authenticate_by_session}
    # Authenticate a record using cookies. Looks for a cookie corresponding to
    # the _authenticatable_class_. If found try to find it in the database.
    # @param authenticatable_class [ActiveRecord::Base] any Model connected to
    #   passwordless. (e.g - _User_ or _Admin_).
    # @return [ActiveRecord::Base|nil] an instance of Model found by id stored
    #   in cookies.encrypted or nil if nothing is found.
    # @see ModelHelpers#passwordless_with
    def authenticate_by_cookie(authenticatable_class)
      key = cookie_name(authenticatable_class)
      authenticatable_id = cookies.encrypted[key]

      return authenticatable_class.find_by(id: authenticatable_id) if authenticatable_id

      authenticate_by_session(authenticatable_class)
    end
    deprecate :authenticate_by_cookie, deprecator: CookieDeprecation

    def upgrade_passwordless_cookie(authenticatable_class)
      key = cookie_name(authenticatable_class)

      return unless (authenticatable_id = cookies.encrypted[key])
      cookies.encrypted.permanent[key] = {value: nil}
      cookies.delete(key)

      return unless (record = authenticatable_class.find_by(id: authenticatable_id))
      new_session = build_passwordless_session(record).tap { |s| s.save! }

      sign_in new_session

      new_session.authenticatable
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
    def sign_in(record)
      passwordless_session =
        if record.is_a?(Passwordless::Session)
          record
        else
          warn "Passwordless::ControllerHelpers#sign_in with authenticatable " \
            "(`#{record.class}') is deprecated. Falling back to creating a " \
            "new Passwordless::Session"
          build_passwordless_session(record).tap { |s| s.save! }
        end

      passwordless_session.claim! if Passwordless.restrict_token_reuse

      raise Passwordless::Errors::SessionTimedOutError if passwordless_session.timed_out?

      key = session_key(passwordless_session.authenticatable_type)
      session[key] = passwordless_session.id

      if record.is_a?(Passwordless::Session)
        passwordless_session
      else
        passwordless_session.authenticatable
      end
    end

    # Signs out user by deleting the session key.
    # @param (see #authenticate_by_session)
    # @return [boolean] Always true
    def sign_out(authenticatable_class)
      # Deprecated - cookies
      key = cookie_name(authenticatable_class)
      cookies.encrypted.permanent[key] = {value: nil}
      cookies.delete(key)
      # /deprecated

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

    # Deprecated
    def cookie_name(authenticatable_class)
      :"#{authenticatable_class.base_class.to_s.underscore}_id"
    end
  end
end
