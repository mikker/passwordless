# frozen_string_literal: true

require "test_helper"

module Passwordless
  class PasswordlessWithTest < ActiveSupport::TestCase
    test "it defines a passwordless email field method" do
      assert_equal :email, User.passwordless_email_field
    end
  end
end
