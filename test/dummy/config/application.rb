require_relative "boot"

require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"

# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"

# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"

# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.action_mailer.default_url_options = {host: "localhost", port: "3000"}
    routes.default_url_options[:host] = "localhost:3000"

    case Rails::VERSION::MAJOR
    when 6
      I18n.available_locales = %i[en test]
    when 7..Float::INFINITY
      config.i18n.available_locales = %i[en test]

      # Silence deprecation warning
      config.active_support.cache_format_version = 7.0
    end
  end
end
