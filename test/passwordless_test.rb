# frozen_string_literal: true

require "test_helper"

module Passwordless
  class PasswordlessTest < ActiveSupport::TestCase
    test(".digest(str)") do
      a = Passwordless.digest("string")
      b = Passwordless.digest("string")

      assert_equal a, b
    end
  end
end
