# frozen_string_literal: true

module Passwordless
  # Generates random numbers for Session records
  class UrlSafeBase64Generator
    # Passwordless' default random string strategy. Generates a url safe
    # base64 random string.
    # @param _session [Session] Optional - Passwordless passes the sesion Record
    # to generators so you can (optionally) use it for generating your tokens.
    # @return [String] 32 byte base64 string
    def call(_session)
      SecureRandom.urlsafe_base64(32)
    end
  end
end
