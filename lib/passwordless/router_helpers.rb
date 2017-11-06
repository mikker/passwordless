module Passwordless
  module RouterHelpers
    def passwordless_for(resource, at: nil)
      mount(
        Passwordless::Engine,
        at: at || resource.to_s,
        as: resource.to_s,
        defaults: { authenticatable: resource.to_s.singularize }
      )
    end
  end
end
