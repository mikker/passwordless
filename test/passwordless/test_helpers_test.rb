require "test_helper"
require "passwordless/test_helpers"

module Passwordless
  class MockTest
    include Rails.application.routes.url_helpers

    def initialize
      @actions = []
      @request = OpenStruct.new(session: {})
    end

    attr_reader :actions, :request
  end

  class MockUnitTest < MockTest
    include Passwordless::TestHelpers::TestCase
  end

  class MockSystemTest < MockTest
    include Passwordless::TestHelpers::SystemTestCase

    def visit(*args)
      @actions << [:visit, args]
    end
  end

  class PasswordlessTestHelpersTest < ActiveSupport::TestCase
    class H
      extend ControllerHelpers
    end

    test("unit test") do
      alice = users(:alice)
      controller = MockUnitTest.new

      controller.passwordless_sign_in(alice)

      assert 1, Session.count
      assert alice, Session.last!.authenticatable
      assert_equal Session.last!.id, controller.request.session[H.session_key(User)]

      controller.passwordless_sign_out(User)
      assert_nil controller.request.session[H.session_key(User)]
    end

    test("system test") do
      alice = users(:alice)
      controller = MockSystemTest.new

      controller.passwordless_sign_in(alice)

      assert 1, Session.count
      assert alice, Session.last!.authenticatable
      assert_match(
        %r{^http://.*/users/sign_in/[a-z0-9-]{36}/[a-z0-9]+}i,
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
