# frozen_string_literal: true

module Passwordless
  module ControllerHelpers
    def authenticate_by_cookie(authenticatable_class)
      key = cookie_name(authenticatable_class)
      authenticatable_id = cookies.encrypted[key]
      return unless authenticatable_id

      authenticatable_class.find_by(id: authenticatable_id)
    end

    def sign_in(authenticatable)
      key = cookie_name(authenticatable.class)
      cookies.encrypted.permanent[key] = { value: authenticatable.id }
      authenticatable
    end

    def sign_out(authenticatable_class)
      key = cookie_name(authenticatable_class)
      cookies.encrypted.permanent[key] = { value: nil }
      cookies.delete(key)
    end

    def save_passwordless_redirect_location!(authenticatable_class)
      session[session_key(authenticatable_class)] = request.original_url
    end

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
