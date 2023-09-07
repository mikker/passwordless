module Passwordless
  module TestHelpers
    module TestCase
      def passwordless_sign_out
        delete(Passwordless::Engine.routes.url_helpers.sign_out_path)
        follow_redirect!
      end

      def passwordless_sign_in(resource)
        session = Passwordless::Session.create!(authenticatable: resource)
        magic_link = Passwordless::Engine.routes.url_helpers.send(
          :"confirm_#{session.authenticatable_type.tableize}_sign_in_url",
          session,
          session.token
        )
        get(magic_link)
        follow_redirect!
      end
    end

    module SystemTestCase
      def passwordless_sign_out
        visit(Passwordless::Engine.routes.url_helpers.sign_out_path)
      end

      def passwordless_sign_in(resource)
        session = Passwordless::Session.create!(authenticatable: resource)
        magic_link = Passwordless::Engine.routes.url_helpers.send(
          :"confirm_#{session.authenticatable_type.tableize}_sign_in_url",
          session,
          session.token
        )
        visit(magic_link)
      end
    end
  end
end

if defined?(ActiveSupport::TestCase)
  ActiveSupport::TestCase.send(:include, ::Passwordless::TestHelpers::TestCase)
end

if defined?(ActionDispatch::SystemTestCase)
  ActionDispatch::SystemTestCase.send(:include, ::Passwordless::TestHelpers::SystemTestCase)
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.include(::Passwordless::TestHelpers::TestCase, type: :request)
    config.include(::Passwordless::TestHelpers::TestCase, type: :controller)
    config.include(::Passwordless::TestHelpers::SystemTestCase, type: :system)
  end
end
