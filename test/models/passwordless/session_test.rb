require "test_helper"

module Passwordless
  class SessionTest < ActiveSupport::TestCase
    test("scope: available") do
      available = create_session
      _timed_out = create_session(expires_at: 1.hour.ago)

      assert_equal [available], Session.available.all
    end

    test("#authenticate") do
      session = create_session(token: "hi")

      assert session.authenticate("hi")
      refute session.authenticate("no")
    end

    test("authenticate with case insensitive tokens") do
      Passwordless.config.case_insensitive_tokens = true
      session = create_session(token: "hi123")

      assert session.authenticate("hi123")
      assert session.authenticate("Hi123")
      assert session.authenticate("HI123")
      refute session.authenticate("no123")
      
      Passwordless.config.case_insensitive_tokens = false
      session = create_session(token: "hi123")

      assert session.authenticate("hi123")
      refute session.authenticate("Hi123")
      refute session.authenticate("HI123")
      refute session.authenticate("no123")
    end

    test("#expired?") do
      expired_session = create_session(expires_at: 1.hour.ago)

      assert_equal expired_session.expired?, true
    end

    test("#timed_out?") do
      timed_out_session = create_session(timeout_at: 1.hour.ago)

      assert_equal timed_out_session.timed_out?, true
    end

    test("#claimed?") do
      claimed_session = create_session(claimed_at: 1.hour.ago)

      assert_equal claimed_session.claimed?, true
    end

    test("sets defaults") do
      session = Session.new
      session.validate

      refute_nil session.expires_at
      refute_nil session.timeout_at
      refute_nil session.token
      refute_nil session.token_digest
    end

    test("with a custom token generator") do
      class AlwaysMeGenerator
        def call(_session)
          "ALWAYS ME"
        end
      end

      old_generator = Passwordless.config.token_generator
      Passwordless.config.token_generator = AlwaysMeGenerator.new

      session = Session.new
      session.validate

      assert_equal "ALWAYS ME", session.token
      assert_equal Passwordless.digest("ALWAYS ME"), session.token_digest

      Passwordless.config.token_generator = old_generator
    end

    test("setting token manually") do
      session = Session.new(token: "hi")
      assert_equal "hi", session.token
      assert_equal Passwordless.digest("hi"), session.token_digest
    end

    test("with a custom expire at function") do
      custom_expire_at = Time.parse("01-01-2100").utc
      old_expires_at = Passwordless.config.expires_at

      Passwordless.config.expires_at = lambda { custom_expire_at }

      session = Session.new
      session.validate

      assert_equal custom_expire_at.to_s, session.expires_at.to_s
      Passwordless.config.expires_at = old_expires_at
    end

    test("with a custom timeout at function") do
      custom_timeout_at = Time.parse("01-01-2100").utc
      old_timeout_at = Passwordless.config.timeout_at

      Passwordless.config.timeout_at = lambda { custom_timeout_at }

      session = Session.new
      session.validate

      assert_equal custom_timeout_at.to_s, session.timeout_at.to_s
      Passwordless.config.timeout_at = old_timeout_at
    end

    test("#claim! - with unclaimed session") do
      unclaimed_session = create_session
      unclaimed_session.claim!

      refute_nil unclaimed_session.claimed_at
    end

    test("#claim! - with claimed session") do
      claimed_session = create_session(claimed_at: 1.hour.ago)

      assert_raises(Passwordless::Errors::TokenAlreadyClaimedError) do
        claimed_session.claim!
      end
    end

    test("#available? - when available") do
      available_session = create_session

      assert available_session.available?
    end

    test("#available? - when unavailable") do
      unavailable_session = create_session(expires_at: 2.years.ago)

      refute unavailable_session.available?
    end

    def create_session(attrs = {})
      user = User.create(email: next_email("valid"))
      Session.create!(attrs.reverse_merge(authenticatable: user))
    end
  end
end
