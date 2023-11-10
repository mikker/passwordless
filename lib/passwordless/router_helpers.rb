# frozen_string_literal: true

module Passwordless
  # Helpers for generating passwordless routes.
  module RouterHelpers
    # Generates passwordless routes for a given Model
    #   Example usage:
    #     passwordless_for :users
    #     # or with options ...
    #     passwordless_for :users, at: 'session_stuff', as: :user_session_things
    #     # or with a custom controller ...
    #     passwordless_for :users, controller: 'my_custom_controller'
    # @param resource [Symbol] the pluralized symbol of a Model (e.g - :users).
    # @param at [String] Optional - provide custom path for the passwordless
    #   engine to get mounted at (using the above example your URLs end
    #   up like: /session_stuff/sign_in). (Default: resource.to_s)
    # @param as [Symbol] Optional - provide custom scope for url
    #   helpers (using the above example in a view:
    #   <%= link_to 'Sign in', user_session_things.sign_in_path %>).
    #   (Default: resource.to_s)
    # @param controller [String] Optional - provide a custom controller for
    #  sessions to use (using the above example the controller called would be MyCustomController
    #  (Default: 'passwordless/sessions')
    def passwordless_for(resource, at: :na, as: :na, controller: "passwordless/sessions")
      at == :na && at = "/#{resource.to_s}"
      as == :na && as = resource.to_s

      as = as.to_s + "_" unless !as || as.to_s.end_with?("_")

      pwless_resource = Passwordless.add_resource(resource, controller: controller)

      scope(defaults: pwless_resource.defaults) do
        get("#{at}/sign_in", to: "#{controller}#new", as: :"#{as}sign_in")
        post("#{at}/sign_in", to: "#{controller}#create")
        get("#{at}/sign_in/:id", to: "#{controller}#show", as: :"verify_#{as}sign_in")
        get("#{at}/sign_in/:id/:token", to: "#{controller}#confirm", as: :"confirm_#{as}sign_in")
        patch("#{at}/sign_in/:id", to: "#{controller}#update")
        match("#{at}/sign_out", to: "#{controller}#destroy", via: %i[get delete], as: :"#{as}sign_out")
      end
    end
  end
end
