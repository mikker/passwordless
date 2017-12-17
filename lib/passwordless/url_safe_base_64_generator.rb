# frozen_string_literal: true

module Passwordless
  # Generates secure random numbers for sessions/cookies, etc.
  class UrlSafeBase64Generator
    # Generates a url safe base64 secure random number :-)
    # @param _session [Object] Optional - pass the session into the generator
    #   to allow using it with a custom token generator.
    # @return [string] secure 32 byte base64 string.
    def call(_session)
      SecureRandom.urlsafe_base64(32)
    end
  end
end
