require "passwordless/short_token_generator"

module Passwordless
  module Options
    module ClassMethods
      def option(name, default: nil)
        attr_accessor(name)
        schema[name] = default
      end

      def schema
        @schema ||= {}
      end
    end

    def set_defaults!
      self.class.schema.each do |name, default|
        instance_variable_set("@#{name}", default)
      end
    end

    def self.included(cls)
      cls.extend(ClassMethods)
    end
  end

  class Configuration
    include Options

    option :default_from_address, default: "CHANGE_ME@example.com"
    option :parent_mailer, default: "ActionMailer::Base"
    option :restrict_token_reuse, default: true
    option :token_generator, default: ShortTokenGenerator.new
    option :combat_brute_force_attacks, default: !Rails.env.test?

    option :expires_at, default: lambda { 1.year.from_now }
    option :timeout_at, default: lambda { 10.minutes.from_now }

    option :redirect_back_after_sign_in, default: true
    option :redirect_to_response_options, default: {}
    option :success_redirect_path, default: "/"
    option :failure_redirect_path, default: "/"
    option :sign_out_redirect_path, default: "/"
    option(
      :after_session_save,
      default: lambda do |session, _request|
        Mailer.sign_in(session, session.token).deliver_now
      end
    )

    option :paranoid, default: false

    def initialize
      set_defaults!
    end
  end

  module Configurable
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def reset_config!
      @config = Configuration.new
    end
  end

end
