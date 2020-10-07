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

    test "scope: available" do
      available = create_session
      _timed_out = create_session expires_at: 1.hour.ago

      assert_equal [available], Session.available.all
    end

    test "expired?" do
      expired_session = create_session expires_at: 1.hour.ago

      assert_equal expired_session.expired?, true
    end

    test "timed_out?" do
      timed_out_session = create_session timeout_at: 1.hour.ago

      assert_equal timed_out_session.timed_out?, true
    end

    test "claimed?" do
      claimed_session = create_session claimed_at: 1.hour.ago

      assert_equal claimed_session.claimed?, true
    end

    test "it has defaults" do
      session = Session.new
      session.validate

      refute_nil session.expires_at
      refute_nil session.timeout_at
      refute_nil session.token
      refute_nil session.token_digest
    end

    test "it generates a digest" do
      session = Session.new
      session.validate

      assert_equal 64, session.token_digest.length
      refute_equal session.token, session.token_digest
    end

    test "with a custom digest algorithm" do
      old_digest_algorithm = Passwordless.digest_algorithm

      Passwordless.digest_algorithm = "SHA1"

      session = Session.new
      session.validate

      assert_equal 40, session.token_digest.length

      Passwordless.digest_algorithm = old_digest_algorithm
    end

    test "with a custom digest secret" do
      digest_a = Passwordless.digest("same_value")

      old_digest_secret = Passwordless.digest_secret
      Passwordless.digest_secret = lambda { "CUSTOM" }

      digest_b = Passwordless.digest("same_value")

      refute_equal digest_a, digest_b

      Passwordless.digest_secret = old_digest_secret
    end

    test "with a custom token generator" do
      class AlwaysMeGenerator
        def call(_value)
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

    test "claim! - with unclaimed session" do
      unclaimed_session = create_session
      unclaimed_session.claim!

      refute_nil unclaimed_session.claimed_at
    end

    test "claim! - with claimed session" do
      claimed_session = create_session claimed_at: 1.hour.ago

      assert_raises(Passwordless::Errors::TokenAlreadyClaimedError) do
        claimed_session.claim!
      end
    end

    test "available? - when available" do
      available_session = create_session

      assert available_session.available?
    end

    test "available? - when unavailable" do
      unavailable_session = create_session expires_at: 2.years.ago

      refute unavailable_session.available?
    end
  end
end
