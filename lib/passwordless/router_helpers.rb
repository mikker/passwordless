# frozen_string_literal: true

module Passwordless
  # Helpers for generating passwordless routes.
  module RouterHelpers
    # Generates passwordless routes for a given Model
    #   Example usage:
    #     passwordless_for :users
    #     # or with options ...
    #     passwordless_for :users, at: 'session_stuff', as: :user_session_things
    # @param resource [Symbol] the pluralized symbol of a Model (e.g - :users).
    # @param at [String] Optional - provide custom path for the passwordless
    #   engine to get mounted at (using the above example your URLs end
    #   up like: /session_stuff/sign_in). (Default: resource.to_s)
    # @param as [Symbol] Optional - provide custom scope for url
    #   helpers (using the above example in a view:
    #   <%= link_to 'Sign in', user_session_things.sign_in_path %>).
    #   (Default: resource.to_s)
    def passwordless_for(resource, at: :na, as: :na)
      at == :na && at = "/#{resource.to_s}"
      as == :na && as = "#{resource.to_s}_"

      scope defaults: {authenticatable: resource.to_s.singularize, resource: resource} do
        get("#{at}/sign_in", to: "passwordless/sessions#new", as: :"#{as}sign_in")
        post("#{at}/sign_in", to: "passwordless/sessions#create")
        get("#{at}/sign_in/:token", to: "passwordless/sessions#show", as: :"#{as}token_sign_in")
        match("#{at}/sign_out", to: "passwordless/sessions#destroy", via: %i[get delete], as: :"#{as}sign_out")
      end
    end
  end
end
