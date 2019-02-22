# frozen_string_literal: true

module Passwordless
  # Helpers to work with Passwordless sessions from controllers
  module ControllerHelpers
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
      return unless authenticatable_id

      authenticatable_class.find_by(id: authenticatable_id)
    end

    # Signs in user by assigning their id to a permanent cookie.
    # @param authenticatable [ActiveRecord::Base] Instance of Model to sign in
    #   (e.g - @user when @user = User.find(id: some_id)).
    # @return [ActiveRecord::Base] the record that is passed in.
    def sign_in(authenticatable)
      key = cookie_name(authenticatable.class)
      cookies.encrypted.permanent[key] = {value: authenticatable.id}
      authenticatable
    end

    # Signs out user by deleting their encrypted cookie.
    # @param (see #authenticate_by_cookie)
    # @return [boolean] Always true
    def sign_out(authenticatable_class)
      key = cookie_name(authenticatable_class)
      cookies.encrypted.permanent[key] = {value: nil}
      cookies.delete(key)
      true
    end

    # Saves request.original_url as the redirect location for a
    # passwordless Model.
    # @param (see #authenticate_by_cookie)
    # @return [String] the redirect url that was just saved.
    def save_passwordless_redirect_location!(authenticatable_class)
      session[session_key(authenticatable_class)] = request.original_url
    end

    # Resets the redirect_location to root_path by deleting the redirect_url
    # from session.
    # @param (see #authenticate_by_cookie)
    # @return [String, nil] the redirect url that was just deleted,
    #   or nil if no url found for given Model.
    def reset_passwordless_redirect_location!(authenticatable_class)
      session.delete session_key(authenticatable_class)
    end

    private

    def session_key(authenticatable_class)
      :"passwordless_prev_location--#{authenticatable_class.base_class}"
    end

    def cookie_name(authenticatable_class)
      :"#{authenticatable_class.base_class.to_s.underscore}_id"
    end
  end
end
