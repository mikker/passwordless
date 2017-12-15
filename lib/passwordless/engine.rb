# frozen_string_literal: true

module Passwordless
  class Engine < ::Rails::Engine
    isolate_namespace Passwordless

    config.to_prepare do
      require 'passwordless/router_helpers'
      ActionDispatch::Routing::Mapper.include RouterHelpers
      require 'passwordless/model_helpers'
      ActiveRecord::Base.extend ModelHelpers
      require 'passwordless/controller_helpers'
    end
  end
end
