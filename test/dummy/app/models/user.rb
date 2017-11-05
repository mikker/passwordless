class User < ApplicationRecord
  def self.passwordless_email_field
    :email
  end
end
