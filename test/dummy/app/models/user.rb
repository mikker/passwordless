class User < ApplicationRecord
  passwordless_with :email
end
