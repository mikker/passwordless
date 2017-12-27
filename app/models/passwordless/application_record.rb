# frozen_string_literal: true

module Passwordless
  # Base record for Passordless' models
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
