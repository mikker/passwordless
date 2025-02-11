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

  LOCK = Mutex.new

  def self.context
    return @context if @context

    # Routes are lazy loaded in Rails 8 so we need to load them to populate Context#resources.
    Rails.application.try(:reload_routes_unless_loaded)

    LOCK.synchronize do
      @context ||= Context.new
    end
  end

  def self.add_resource(resource, controller:, **defaults)
    context.resources[resource] = Resource.new(resource, controller: controller)
  end

  def self.digest(token)
    TokenDigest.new(token).digest
  end
end
