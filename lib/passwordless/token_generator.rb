require 'openssl'

module Passwordless
  class TokenGenerator
    def initialize(key_generator, friendly_token_generator, digest)
      @key = key_generator.generate_key('passwordless')
      @friendly_token_generator = friendly_token_generator
      @digest = digest
    end

    def digest(value)
      value.present? && OpenSSL::HMAC.hexdigest(@digest, @key, value.to_s)
    end

    def generate(klass)
      loop do
        raw = @friendly_token_generator.call(klass)
        enc = OpenSSL::HMAC.hexdigest(@digest, @key, raw)
        break [raw, enc] unless klass.find_by(token_digest: enc)
      end
    end
  end
end
