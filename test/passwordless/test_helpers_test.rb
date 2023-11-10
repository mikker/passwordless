require "test_helper"
require "passwordless/test_helpers"

module Passwordless
  class MockTest
    include Rails.application.routes.url_helpers

    def initialize
      @actions = []
    end

    attr_reader :actions
  end

  class MockUnitTest < MockTest
    include Passwordless::TestHelpers::TestCase

    def get(*args)
      @actions << [:get, args]
    end

    def delete(*args)
      @actions << [:delete, args]
    end

    def follow_redirect!
      @actions << [:follow_redirect!]
    end
  end

  class MockSystemTest < MockTest
    include Passwordless::TestHelpers::SystemTestCase

    def visit(*args)
      @actions << [:visit, args]
    end
  end

  class PasswordlessTestHelpersTest < ActiveSupport::TestCase
    test("unit test") do
      alice = users(:alice)
      controller = MockUnitTest.new

      controller.passwordless_sign_in(alice)

      assert 1, Session.count
      assert alice, Session.last!.authenticatable
      assert_match(
        %r{/users/sign_in/[a-z0-9-]+/[a-z0-9]+}i,
        controller.actions.first.last.first
      )

      controller.passwordless_sign_out

      assert_match(
        %r{/users/sign_out},
        controller.actions[-2].last.first
      )
    end

    test("system test") do
      alice = users(:alice)
      controller = MockSystemTest.new

      controller.passwordless_sign_in(alice)

      assert 1, Session.count
      assert alice, Session.last!.authenticatable
      assert_match(
        %r{^http://.*/users/sign_in/[a-z0-9]+/[a-z0-9]+}i,
        controller.actions.last.last.first
      )

      controller.passwordless_sign_out

      assert_match(
        %r{^http://.*/users/sign_out},
        controller.actions.last.last.first
      )
    end
  end
end
