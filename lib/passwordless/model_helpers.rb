# frozen_string_literal: true

module Passwordless
  # Some helpers for models that can sign in passswordlessly.
  module ModelHelpers
    # Creates relationship - has_many :passwordless_sessions
    # Defines a method `Class.passwordless_email_field` returning its email
    #   field name (e.g. `:email`)
    # @param field [string] email submitted by user.
    def passwordless_with(field)
      has_many :passwordless_sessions,
        class_name: "Passwordless::Session",
        as: :authenticatable

      define_singleton_method(:passwordless_email_field) { field }
    end
  end
end
