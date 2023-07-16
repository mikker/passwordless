# frozen_string_literal: true

require "active_support"
require "passwordless/config"
require "passwordless/errors"
require "passwordless/engine"
require "passwordless/token_digest"

# The main Passwordless module
module Passwordless
  extend Configurable

  def self.digest(token)
    TokenDigest.new(token).digest
  end
end
