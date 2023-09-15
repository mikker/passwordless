# frozen_string_literal: true

require "test_helper"

module Passwordless
  class ControllerHelpersTest < ActiveSupport::TestCase
    class Helpers
      extend ControllerHelpers
    end

    test("#build_passwordless_session") do
      alice = users(:alice)
      session = Helpers.build_passwordless_session(alice)

      assert_equal alice, session.authenticatable
      assert session.new_record?
      refute session.persisted?
    end

    test("#create_passwordless_session") do
      alice = users(:alice)

      assert Helpers.create_passwordless_session(alice)
      assert_equal alice, Session.last!.authenticatable

      refute Helpers.create_passwordless_session(nil)
    end

    test("#create_passwordless_session!") do
      alice = users(:alice)

      session = Helpers.create_passwordless_session!(alice)
      assert_equal alice, session.authenticatable

      assert_raise do
        Helpers.create_passwordless_session!(nil)
      end
    end
  end
end
