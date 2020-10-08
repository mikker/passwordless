# frozen_string_literal: true

module Passwordless
  class TokenDigest
    ALGORITHM = "SHA256"

    def initialize(str)
      @str = str
    end

    def digest
      key = self.class.key
      OpenSSL::HMAC.hexdigest(ALGORITHM, key, @str)
    end

    def self.key
      @key ||= ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("passwordless")
    end
  end
end
