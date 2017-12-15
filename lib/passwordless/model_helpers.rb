# frozen_string_literal: true

module Passwordless
  # Some helpers for models that can sign in passswordlessly
  module ModelHelpers
    def passwordless_with(field)
      has_many :passwordless_sessions, class_name: 'Passwordless::Session'
      define_singleton_method(:passwordless_email_field) { field }
    end
  end
end
