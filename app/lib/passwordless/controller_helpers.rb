module Passwordless
  module ControllerHelpers

    def authenticate!(authenticatable_class)
      key = :"#{authenticatable_class.to_s.underscore}_id"
      authenticatable_id = cookies.encrypted[key]
      return unless authenticatable_id

      authenticatable_class.find_by(id: authenticatable_id)
    end

    def sign_in!(authenticatable)
      key = :"#{authenticatable.class.to_s.underscore}_id"
      cookies.encrypted.permanent[key] = { value: authenticatable.id }
      authenticatable
    end

    def sign_out!(authenticatable_class)
      key = :"#{authenticatable_class.to_s.underscore}_id"
      cookies.encrypted.permanent[key] = { value: nil }
      cookies.delete(key)
    end

    # def self.included(kls)
    #   kls.class_eval do
    #     # helper_method :current_user
    #   end
    # end
  end
end
