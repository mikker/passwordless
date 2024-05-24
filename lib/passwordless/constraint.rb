# frozen_string_literal: true

require 'passwordless/controller_helpers'

module Passwordless
  class Constraint
    include ControllerHelpers

    attr_reader :authenticatable_type, :authenticated, :lambda, :session

    def initialize(authenticatable_type, lambda = -> { true }, authenticated: true)
      @authenticatable_type = authenticatable_type
      @authenticated = authenticated
      @lambda = lambda
    end

    def matches?(request)
      @session = request.session
      authenticatable = authenticate_by_session(authenticatable_type)
      authenticatable.present? == authenticated && lambda.call(authenticatable)
    end
  end
end
