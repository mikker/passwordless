# frozen_string_literal: true

begin
  require "bundler/setup"

rescue LoadError
  puts("You must `gem install bundler` and `bundle install` to run rake tasks")
end

require "yard"

YARD::Rake::YardocTask.new
task(docs: :yard)

APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)
load("rails/tasks/engine.rake")
load("rails/tasks/statistics.rake")

require "bundler/gem_tasks"

task(:test) do
  puts("Use `bin/rails test`")
  puts("-" * 80)
  system("bin/rails test")
end

task(default: :test)
