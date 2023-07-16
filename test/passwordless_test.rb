require "test_helper"

module Passwordless
  class PasswordlessTest < ActiveSupport::TestCase
    test(".digest(str)") do
      a = Passwordless.digest("string")
      b = Passwordless.digest("string")

      assert_equal a, b
    end

    test("has config") do
      assert Passwordless.config.is_a?(Passwordless::Configuration)
    end

    test("can configure") do
      Passwordless.configure do |config|
        config.default_from_address = "hello"
      end

      assert_equal "hello", Passwordless.config.default_from_address
    end

    test("can reset configuration") do
      Passwordless.configure do |config|
        config.default_from_address = "hello"
      end

      Passwordless.reset_config!

      assert_equal "CHANGE_ME@example.com", Passwordless.config.default_from_address
    end
  end
end
