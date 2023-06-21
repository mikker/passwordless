# frozen_string_literal: true

module Passwordless
  module Errors
    # Raised when the authenticatable class is not found.
    class MissingEmailFieldError < StandardError
    end

    # Raise this exception when a session is expired.
    class SessionTimedOutError < StandardError
    end

    # Raise this exception when the token has been previously claimed
    class TokenAlreadyClaimedError < StandardError
    end
  end
end
