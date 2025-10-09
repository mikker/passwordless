module Passwordless
  class ShortTokenGenerator
    CHARS = [*"A".."Z", *"0".."9"].freeze

    def call(_session)
      SecureRandom.alphanumeric(6, chars: CHARS)
    end
  end
end
