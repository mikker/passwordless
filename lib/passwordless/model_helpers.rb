# frozen_string_literal: true

module Passwordless
  module ModelHelpers
    def passwordless_with(field)
      define_singleton_method(:passwordless_email_field) { field }
    end
  end
end
