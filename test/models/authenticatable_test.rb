# frozen_string_literal: true

require "test_helper"

class AuthenticatableTest < ActiveSupport::TestCase
  test "#passwordless_sessions" do
    user = users(:john)
    assert_equal [passwordless_sessions(:john)], user.passwordless_sessions
  end
end
