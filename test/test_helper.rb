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
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
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

    yield
  ensure
    Passwordless.reset_config!
  end
end

include(WithConfig)
