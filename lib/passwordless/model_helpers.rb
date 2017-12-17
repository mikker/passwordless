# frozen_string_literal: true

module Passwordless
  # Some helpers for models that can sign in passswordlessly. These helpers
  # are used to hook up SomeModel with passwordless_sessions.
  module ModelHelpers
    # Adds passwordless sign_in for SomeModel (examples: User, Admin).
    #   Creates relationship - has_many :passwordless_sessions
    #   Allows - Call SomeModel.passwordless_email_field to return email used.
    # @param field [string] email submitted by user.
    def passwordless_with(field)
      has_many :passwordless_sessions, class_name: 'Passwordless::Session'
      define_singleton_method(:passwordless_email_field) { field }
    end
  end
end
