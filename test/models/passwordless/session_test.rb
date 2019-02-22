# frozen_string_literal: true

require "test_helper"

module Passwordless
  class SessionTest < ActiveSupport::TestCase
    def create_session(attrs = {})
      Session.create!(
        attrs.reverse_merge(
          remote_addr: "0.0.0.0",
          user_agent: "wooden box",
          authenticatable: User.create(email: "session_test_valid@a")
        )
      )
    end

    test "scope: valid" do
      valid = create_session
      _timed_out = create_session timeout_at: 1.hour.ago

      assert_equal [valid], Session.valid.all
    end

    test "expired?" do
      expired_session = create_session expires_at: 1.hour.ago

      assert_equal expired_session.expired?, true
    end

    test "timed_out?" do
      timed_out_session = create_session timeout_at: 1.hour.ago

      assert_equal timed_out_session.timed_out?, true
    end

    test "it has defaults" do
      session = Session.new
      session.validate

      refute_nil session.expires_at
      refute_nil session.timeout_at
      refute_nil session.token
    end

    test "with a custom token generator" do
      class AlwaysMeGenerator
        def call(_session)
          "ALWAYS ME"
        end
      end

      old_generator = Passwordless.token_generator
      Passwordless.token_generator = AlwaysMeGenerator.new

      session = Session.new
      session.validate

      assert_equal "ALWAYS ME", session.token

      Passwordless.token_generator = old_generator
    end

    test "with a custom expire at function" do
      custom_expire_at = Time.parse("01-01-2100").utc
      old_expires_at = Passwordless.expires_at

      Passwordless.expires_at = lambda { custom_expire_at }

      session = Session.new
      session.validate

      assert_equal custom_expire_at.to_s, session.expires_at.to_s
      Passwordless.expires_at = old_expires_at
    end

    test "with a custom timeout at function" do
      custom_timeout_at = Time.parse("01-01-2100").utc
      old_timeout_at = Passwordless.timeout_at

      Passwordless.timeout_at = lambda { custom_timeout_at }

      session = Session.new
      session.validate

      assert_equal custom_timeout_at.to_s, session.timeout_at.to_s
      Passwordless.timeout_at = old_timeout_at
    end
  end
end
