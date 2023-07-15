# frozen_string_literal: true

module Passwordless
  # Engine that runs the passwordless gem.
  class Engine < ::Rails::Engine
    config.to_prepare do
      require "passwordless/router_helpers"
      require "passwordless/model_helpers"
      require "passwordless/controller_helpers"

      ActionDispatch::Routing::Mapper.include RouterHelpers
      ActiveRecord::Base.extend ModelHelpers
    end

    config.before_initialize do |app|
      app.config.i18n.load_path += Dir[Engine.root.join("config", "locales", "*.yml")]
    end
  end
end
