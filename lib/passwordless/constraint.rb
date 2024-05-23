# frozen_string_literal: true

require "passwordless/controller_helpers"

module Passwordless
  class Constraint
    include ControllerHelpers

    attr_reader :authenticatable_type, :session, :lambda

    def initialize(authenticatable_type, lambda)
      @authenticatable_type = authenticatable_type
      @lambda = lambda
    end

    def matches?(request)
      @session = request.session
      authenticatable = authenticate_by_session(authenticatable_type)
      authenticatable.present? && lambda.call(authenticatable)
    end
  end
end
