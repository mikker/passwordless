# frozen_string_literal: true

module Passwordless
  # Some helpers for controllers that are connected to passswordless Models.
  # These helpers give the ability to sign_in/out of a session, authenticate a
  # session, and save/reset the passwordless redirect path.
  module ControllerHelpers
    # Authenticate a model using cookies. Will create a key from the model name
    # and check if there is a value in cookies for that key.
    # @param authenticatable_class [Object] any Model connected to passwordless.
    #   ( e.g - User or Admin ).
    # @return [Object, nil] an instance of Model found by id stored in
    #   cookies.encrypted at key: key_from_model_name,
    #   or nil if no value corresponds to that key.
    def authenticate_by_cookie(authenticatable_class)
      key = cookie_name(authenticatable_class)
      authenticatable_id = cookies.encrypted[key]
      return unless authenticatable_id

      authenticatable_class.find_by(id: authenticatable_id)
    end

    # Signs in user by assigning her id to a permanent cookie.
    # @param authenticatable [Object] instance of Model to sign in
    #   ( e.g - @user when @user = User.find(id: some_id) ).
    # @return [Object] the Object that is passed in.
    def sign_in(authenticatable)
      key = cookie_name(authenticatable.class)
      cookies.encrypted.permanent[key] = { value: authenticatable.id }
      authenticatable
    end

    # Signs out user by deleting her id from permanent cookies.
    # @param (see #authenticate_by_cookie)
    # @return [Integer, nil] the id that was deleted from cookies, or nil
    #   if no value found for provided key.
    def sign_out(authenticatable_class)
      key = cookie_name(authenticatable_class)
      cookies.encrypted.permanent[key] = { value: nil }
      cookies.delete(key)
    end

    # Saves request.original_url as the redirect location
    # for a passwordless Model.
    # @param (see #authenticate_by_cookie)
    # @return [String] the redirect url that was just saved.
    def save_passwordless_redirect_location!(authenticatable_class)
      session[session_key(authenticatable_class)] = request.original_url
    end

    # Resets the redirect_location to root_path by deleting the
    # redirect_url fromsession.
    # @param (see #authenticate_by_cookie)
    # @return [String, nil] the redirect url that was just deleted,
    #   or nil if no url found for given Model.
    def reset_passwordless_redirect_location!(authenticatable_class)
      session.delete session_key(authenticatable_class)
    end

    private

    def session_key(authenticatable_class)
      :"passwordless_prev_location--#{authenticatable_class}"
    end

    def cookie_name(authenticatable_class)
      :"#{authenticatable_class.to_s.underscore}_id"
    end
  end
end
