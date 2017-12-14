# frozen_string_literal: true

module Passwordless
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
