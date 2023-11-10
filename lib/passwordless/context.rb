# frozen_string_literal: true

module Passwordless
  class Resource
    def initialize(resource, controller:)
      @resource = resource
      @authenticatable = resource.to_s.singularize.to_sym
      @controller = controller
    end

    attr_reader :resource, :authenticatable, :controller

    def defaults
      @defaults ||= {
        authenticatable: authenticatable,
        resource: resource,
        controller: controller
      }
    end
  end

  class Context
    def initialize
      @resources = {}
    end

    attr_reader :resources

    def resource_for(session_or_authenticatable)
      if session_or_authenticatable.is_a?(Session)
        session_or_authenticatable = session_or_authenticatable.authenticatable.model_name.to_s.tableize.to_sym
      end

      resources[session_or_authenticatable.to_sym]
    end

    def url_for(session_or_authenticatable, **options)
      unless (resource = resource_for(session_or_authenticatable))
        raise ArgumentError, "No resource registered for #{session_or_authenticatable}"
      end

      Rails.application.routes.url_helpers.url_for(
        resource.defaults.merge(options)
      )
    end

    def path_for(session_or_authenticatable, **options)
      url_for(session_or_authenticatable, only_path: true, **options)
    end
  end
end
