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

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("../fixtures", __FILE__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_paths.first + "/files"
  ActiveSupport::TestCase.fixtures(:all)
end

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

    # We need to reload the application, because the config can set a different
    # parent class for the mailer, which means `Passwordless::Mailer` needs to be
    # reloaded.
    reload_mailer! if options.has_key?(:parent_mailer)

    yield
  ensure
    Passwordless.reset_config!

    # Reload the application again, because we reset the config.
    reload_mailer! if options.has_key?(:parent_mailer)
  end

  private

  # Reloads the Mailer by removing its constant and reloading the mailer file manually.
  # This is quite a hack, but it seems to work.
  def reload_mailer!
    Passwordless.send(:remove_const, :Mailer)
    load File.expand_path("../../app/mailers/passwordless/mailer.rb", __FILE__)
  end
end

include(WithConfig)
