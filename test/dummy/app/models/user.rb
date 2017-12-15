# frozen_string_literal: true

class User < ApplicationRecord
  passwordless_with :email
end
