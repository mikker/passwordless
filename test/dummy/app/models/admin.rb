# frozen_string_literal: true

class Admin < ApplicationRecord
  passwordless_with :email
end
