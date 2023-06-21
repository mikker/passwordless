module Passwordless
  class ShortTokenGenerator
    CHARS = [*"A".."Z", *"0".."9"].freeze

    def call(_session)
      CHARS.sample(6).join
    end
  end
end
