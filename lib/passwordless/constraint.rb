# frozen_string_literal: true

require "passwordless/controller_helpers"

module Passwordless
  # A class the constraint routes to authenticated records
  class Constraint
    include ControllerHelpers

    attr_reader :authenticatable_type, :predicate, :session

    # @param [Class] authenticatable_type Authenticatable class
    # @option options [Proc] :if A lambda that takes an authenticatable and returns a boolean
    def initialize(authenticatable_type, **options)
      @authenticatable_type = authenticatable_type
      # `if' is a keyword but so we do this instead of keyword arguments
      @predicate = options.fetch(:if) { -> (_) { true } }
    end

    def matches?(request)
      # used in authenticate_by_session
      @session = request.session
      authenticatable = authenticate_by_session(authenticatable_type)
      !!(authenticatable && predicate.call(authenticatable))
    end
  end

  # A class the constraint routes to NOT authenticated records
  class ConstraintNot < Constraint
    # @param [Class] authenticatable_type Authenticatable class
    # @option options [Proc] :if A lambda that takes an authenticatable and returns a boolean
    def initialize(authenticatable_type, **options)
      super
    end

    def matches?(request)
      !super
    end
  end
end
