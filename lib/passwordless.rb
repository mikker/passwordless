# frozen_string_literal: true

require 'passwordless/engine'
require 'passwordless/url_safe_base_64_generator'

# The main Passwordless module
module Passwordless
  mattr_accessor(:default_from_address) { 'CHANGE_ME@example.com' }
  mattr_accessor(:token_generator) { UrlSafeBase64Generator.new }
  mattr_accessor(:redirect_back_after_sign_in) { true }
  mattr_accessor(:mounted_as) { :configured_when_mounting_passwordless }
end
