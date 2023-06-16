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
    config.load_defaults 7.0

    routes.default_url_options[:host] = "localhost:3000"
    config.action_mailer.default_url_options = {host: "localhost", port: "3000"}
    config.hosts << "www.example.com"
  end
end
