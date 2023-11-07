module Passwordless
  module TestHelpers
    module TestCase
      def passwordless_sign_out(cls = nil)
        cls ||= "User".constantize
        dest = url_for(
          {
            controller: "passwordless/sessions",
            action: "destroy",
            authenticatable: cls.model_name.singular,
            resource: cls.model_name.plural
          }
        )
        delete(dest)
        follow_redirect!
      end

      def passwordless_sign_in(resource)
        cls = resource.class
        session = Passwordless::Session.create!(authenticatable: resource)
        magic_link = url_for(
          {
            controller: "passwordless/sessions",
            action: "confirm",
            id: session.id,
            token: session.token,
            authenticatable: cls.model_name.singular,
            resource: cls.model_name.plural
          }
        )
        get(magic_link)
        follow_redirect!
      end
    end

    module SystemTestCase
      def passwordless_sign_out(cls = nil)
        cls ||= "User".constantize
        visit(
          url_for(
            {
              controller: "passwordless/sessions",
              action: "destroy",
              authenticatable: cls.model_name.singular,
              resource: cls.model_name.plural
            }
          )
        )
      end

      def passwordless_sign_in(resource)
        cls = resource.class
        session = Passwordless::Session.create!(authenticatable: resource)
        magic_link = url_for(
          {
            controller: "passwordless/sessions",
            action: "confirm",
            id: session.id,
            token: session.token,
            authenticatable: cls.model_name.singular,
            resource: cls.model_name.plural
          }
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
