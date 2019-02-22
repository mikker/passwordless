# frozen_string_literal: true

module Passwordless
  # Engine that runs the passwordless gem.
  class Engine < ::Rails::Engine
    isolate_namespace Passwordless

    config.to_prepare do
      require "passwordless/router_helpers"
      ActionDispatch::Routing::Mapper.include RouterHelpers
      require "passwordless/model_helpers"
      ActiveRecord::Base.extend ModelHelpers
      require "passwordless/controller_helpers"
    end

    config.before_initialize do |app|
      app.config.i18n.load_path +=
        Dir[Engine.root.join("config", "locales", "*.yml")]
    end
  end
end
