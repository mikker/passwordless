# frozen_string_literal: true

module Passwordless
  # The session responsible for holding the connection between the record
  # trying to log in and the unique tokens.
  class Session < ApplicationRecord
    self.table_name = "passwordless_sessions"

    belongs_to(
      :authenticatable,
      polymorphic: true,
      inverse_of: :passwordless_sessions
    )

    validates(
      :authenticatable,
      :timeout_at,
      :expires_at,
      :user_agent,
      :remote_addr,
      :token_digest,
      presence: true
    )

    before_validation :set_defaults

    scope(
      :available,
      lambda { where("expires_at > ?", Time.current) }
    )

    # save the token in memory so we can put it in emails but only save the
    # hashed version in the database
    attr_reader :token

    def token=(plaintext)
      self.token_digest = Passwordless.digest(plaintext)
      @token = (plaintext)
    end

    def expired?
      expires_at <= Time.current
    end

    def timed_out?
      timeout_at <= Time.current
    end

    def claim!
      raise Errors::TokenAlreadyClaimedError if claimed?
      touch(:claimed_at)
    end

    def claimed?
      !!claimed_at
    end

    def available?
      !expired?
    end

    private

    def token_digest_available?(token_digest)
      Session.available.where(token_digest: token_digest).none?
    end

    def set_defaults
      self.expires_at ||= Passwordless.expires_at.call
      self.timeout_at ||= Passwordless.timeout_at.call

      return if self.token_digest

      self.token, self.token_digest = loop {
        token = Passwordless.token_generator.call(self)
        digest = Passwordless.digest(token)
        break [token, digest] if token_digest_available?(digest)
      }
    end
  end
end
