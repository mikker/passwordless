# frozen_string_literal: true

# Namespace for classes and modules that handle the MVC for the
# passwordless Gem.
# This is the main module for this gem.
module Passwordless
  # Base Controller Class. All controllers inherit from here.
  class ApplicationController < ::ApplicationController
    # Always returns true. Used to check if <Some>Controller inherits
    # from ApplicationController.
    # @return [boolean]
    def passwordless_controller?
      true
    end
  end
end
