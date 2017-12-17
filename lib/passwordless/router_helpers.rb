# frozen_string_literal: true

module Passwordless
  # Some helpers for generating passwordless routes.
  module RouterHelpers
    # Generates passwordless routes for any Model connected to Passwordless.
    #   Example usage:
    #   passwordless_for :users, at: 'session_stuff', as: :user_session_things
    # @param resource [Symbol] the pluralized symbol of a Model (e.g - :users).
    # @param at [String] Optional - provide custom path for the passwordless
    #   engine to get mounted at (using the above example your URLs end
    #   up like: /session_stuff/sign_in)
    # @param as [Symbol] Optional - provide custom scope for url
    #   helpers (using the above example in a view:
    #   <%= link_to 'Sign in', user_session_things.sign_in_path %>)
    def passwordless_for(resource, at: nil, as: nil)
      mount(
        Passwordless::Engine,
        at: at || resource.to_s,
        as: as || resource.to_s,
        defaults: { authenticatable: resource.to_s.singularize }
      )
    end
  end
end
