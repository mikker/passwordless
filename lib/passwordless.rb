# frozen_string_literal: true

require "active_support"
require "passwordless/config"
require "passwordless/context"
require "passwordless/constraint"
require "passwordless/errors"
require "passwordless/engine"
require "passwordless/token_digest"

# The main Passwordless module
module Passwordless
  extend Configurable

  def self.context
    @context ||= Context.new
  end

  def self.add_resource(resource, controller:, **defaults)
    context.resources[resource] = Resource.new(resource, controller: controller)
  end

  def self.digest(token)
    TokenDigest.new(token).digest
  end
end
