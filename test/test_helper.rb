# frozen_string_literal: true

require "simplecov"
require "minitest"

SimpleCov.start do
  add_filter("test/dummy")
end

if ENV["CI"] && !ENV["CODECOV_TOKEN"].empty?
  require "codecov"

  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)

ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../../db/migrate", __FILE__)
require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

def Minitest.filter_backtrace(bt)
  bt.select { |line| line !~ %r{/gems/} }
end

module EmailHelper
  def next_email(prefix = "email")
    @i ||= 0
    @i += 1
    [prefix, @i, "@example.com"].join
  end
end

include(EmailHelper)

module WithConfig
  def with_config(options)
    Passwordless.configure do |config|
      options.each do |key, value|
        config.send("#{key}=", value)
      end
    end

    yield
  ensure
    Passwordless.reset_config!
  end

  # Reloads the Mailer by removing its constant and reloading the mailer file
  # manually. This is quite a hack, but it seems to work.
  #
  # This can be used when you change the`parent_mailer` config option and need
  # it load a different parent class.
  def reload_mailer!
    return unless defined?(Passwordless::Mailer)
    Passwordless.send(:remove_const, :Mailer)
    load(File.expand_path("../../app/mailers/passwordless/mailer.rb", __FILE__))
  end

  def reload_controller!
    return unless defined?(Passwordless::SessionsController)
    Passwordless.send(:remove_const, :SessionsController)
    load(File.expand_path("../../app/controllers/passwordless/sessions_controller.rb", __FILE__))
  end
end

include(WithConfig)

module FixturePaths
  def self.included(base)
    base.class_eval do
      fixture_path_ = File.expand_path("./fixtures", __dir__)

      if respond_to?(:fixture_paths=)
        self.fixture_paths = [fixture_path_]
      elsif respond_to?(:fixture_path=)
        self.fixture_path = fixture_path_
      else
        self.file_fixture_path = "#{fixture_path_}/files"
      end

      fixtures(:all)
    end
  end
end

class ActionDispatch::IntegrationTest
  include FixturePaths
end

class ActiveSupport::TestCase
  include FixturePaths
end
