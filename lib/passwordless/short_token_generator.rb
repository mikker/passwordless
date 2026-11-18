module Passwordless
  class ShortTokenGenerator
    CHARS = [*"A".."Z", *"0".."9"].freeze

    def initialize(chars: CHARS, size: 6)
      @chars = chars
      @size = size
    end

    def call(_session)
      @chars.sample(@size, random: SecureRandom).join
    end
  end
end
