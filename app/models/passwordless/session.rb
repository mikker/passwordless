# frozen_string_literal: true

module Passwordless
  # The session responsible for holding the connection between the record
  # trying to log in and the unique tokens.
  class Session < ApplicationRecord
    belongs_to :authenticatable,
      polymorphic: true, inverse_of: :passwordless_sessions

    validates \
      :authenticatable,
      :timeout_at,
      :expires_at,
      :user_agent,
      :remote_addr,
      :token_digest,
      presence: true

    before_validation :set_defaults

    attr_accessor :token

    scope :available, lambda {
      where("expires_at > ?", Time.current)
    }

    def self.valid
      available
    end
    class << self
      deprecate :valid, deprecator: SessionValidDeprecation
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

    def set_defaults
      self.expires_at ||= Passwordless.expires_at.call
      self.timeout_at ||= Passwordless.timeout_at.call

      if not self.token or not self.token_digest
        self.token, self.token_digest = Passwordless.token_generator.generate(Session)
      end
    end
  end
end
