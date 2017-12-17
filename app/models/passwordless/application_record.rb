# frozen_string_literal: true

module Passwordless
  # Classic Rails class to abstractify and insulate ActiveRecord:Base.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
