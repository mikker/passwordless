require "test_helper"

module Passwordless
  class ShortTokenGeneratorTest < ActiveSupport::TestCase
    test("generates tokens") do
      assert_match(/^[A-Z0-9]{6}$/, ShortTokenGenerator.new.call(nil))
    end

    test("generates tokens with custom chars and size") do
      generator = ShortTokenGenerator.new(chars: %w[0 1], size: 8)
      assert_match(/^[01]{8}$/, generator.call(nil))
    end
  end
end
