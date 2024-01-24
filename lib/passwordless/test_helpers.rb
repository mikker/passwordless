module Passwordless
  module TestHelpers
    module ControllerTestCase
      class H
        extend ControllerHelpers
      end

      def passwordless_sign_out(cls = nil)
        cls ||= "User".constantize
        @request.session.delete(H.session_key(cls))
      end

      def passwordless_sign_in(resource)
        session = Passwordless::Session.create!(authenticatable: resource)
        @request.session[H.session_key(resource.class)] = session.id
      end
    end

    module RequestTestCase
      def passwordless_sign_out(cls = nil)
        cls ||= "User".constantize
        resource = cls.model_name.to_s.tableize

        dest = Passwordless.context.path_for(resource, action: "destroy")
        delete(dest)

        follow_redirect!
      end

      def passwordless_sign_in(resource)
        session = Passwordless::Session.create!(authenticatable: resource)

        magic_link = Passwordless.context.path_for(
          session,
          action: "confirm",
          id: session.to_param,
          token: session.token
        )

        get(magic_link)
        follow_redirect!
      end
    end

    module SystemTestCase
      def passwordless_sign_out(cls = nil, only_path: false)
        cls ||= "User".constantize
        resource = cls.model_name.to_s.tableize

        visit(Passwordless.context.url_for(resource, action: "destroy", only_path: only_path))
      end

      def passwordless_sign_in(resource, only_path: false)
        session = Passwordless::Session.create!(authenticatable: resource)

        magic_link = Passwordless.context.url_for(
          session,
          action: "confirm",
          id: session.to_param,
          token: session.token,
          only_path: only_path
        )

        visit(magic_link)
      end
    end
  end
end

if defined?(ActiveSupport::TestCase)
  ActiveSupport::TestCase.send(:include, ::Passwordless::TestHelpers::ControllerTestCase)
end

if defined?(ActionDispatch::SystemTestCase)
  ActionDispatch::SystemTestCase.send(:include, ::Passwordless::TestHelpers::SystemTestCase)
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.include(::Passwordless::TestHelpers::ControllerTestCase, type: :controller)
    config.include(::Passwordless::TestHelpers::RequestTestCase, type: :request)
    config.include(::Passwordless::TestHelpers::SystemTestCase, type: :system)
  end
end
