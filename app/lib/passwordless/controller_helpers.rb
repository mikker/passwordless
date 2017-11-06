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

    private

    def cookie_name(authenticatable_class)
      :"#{authenticatable_class.to_s.underscore}_id"
    end
  end
end
