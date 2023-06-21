require "test_helper"

module Passwordless
  class ShortTokenGeneratorTest < ActiveSupport::TestCase
    test("generates tokens") do
      assert_match(/^[A-Z0-9]{6}$/, ShortTokenGenerator.new.call(nil))
    end
  end
end
