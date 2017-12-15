# frozen_string_literal: true

module Passwordless
  module RouterHelpers
    def passwordless_for(resource, at: nil, as: nil)
      mount(
        Passwordless::Engine,
        at: at || resource.to_s,
        as: as || resource.to_s,
        defaults: { authenticatable: resource.to_s.singularize }
      )
    end
  end
end
