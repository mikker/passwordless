# frozen_string_literal: true

module Passwordless
  class ApplicationController < ::ApplicationController
    def passwordless_controller?
      true
    end
  end
end
