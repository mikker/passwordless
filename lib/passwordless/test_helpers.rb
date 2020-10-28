module Passwordless
  module TestHelpers
    module TestCase
      def passwordless_sign_out
        delete Passwordless::Engine.routes.url_helpers.sign_out_path
        follow_redirect!
      end

      def passwordless_sign_in(resource = nil)
        if resource
          session = Passwordless::Session.create!(authenticatable: resource, user_agent: "TestAgent", remote_addr: "unknown")
          get Passwordless::Engine.routes.url_helpers.token_sign_in_path(session.token)
          follow_redirect!
        else
          get Passwordless::Engine.routes.url_helpers.sign_in_path
        end
      end
    end

    module SystemTestCase
      def passwordless_sign_out
        visit Passwordless::Engine.routes.url_helpers.sign_out_path
      end

      def passwordless_sign_in(resource = nil)
        if resource
          session = Passwordless::Session.create!(authenticatable: resource, user_agent: "TestAgent", remote_addr: "unknown")
          visit Passwordless::Engine.routes.url_helpers.token_sign_in_path(session.token)
        else
          visit Passwordless::Engine.routes.url_helpers.sign_in_path
        end
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
    config.include ::Passwordless::TestHelpers::TestCase, type: :request
    config.include ::Passwordless::TestHelpers::TestCase, type: :controller
    config.include ::Passwordless::TestHelpers::SystemTestCase, type: :system
  end
end
