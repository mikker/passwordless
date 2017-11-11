require 'passwordless/engine'
require 'passwordless/url_safe_base_64_generator'

module Passwordless
  mattr_accessor(:default_from_address) { 'CHANGE_ME@example.com' }
  mattr_accessor(:token_generator) do
    UrlSafeBase64Generator.new
  end
end
