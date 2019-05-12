# frozen_string_literal: true

require "active_support"
require "passwordless/errors"
require "passwordless/engine"
require "passwordless/url_safe_base_64_generator"

# The main Passwordless module
module Passwordless
  mattr_accessor(:default_from_address) { "CHANGE_ME@example.com" }
  mattr_accessor(:token_generator) { UrlSafeBase64Generator.new }
  mattr_accessor(:restrict_token_reuse) { false }
  mattr_accessor(:redirect_back_after_sign_in) { true }
  mattr_accessor(:mounted_as) { :configured_when_mounting_passwordless }

  mattr_accessor(:expires_at) { lambda { 1.year.from_now } }
  mattr_accessor(:timeout_at) { lambda { 1.hour.from_now } }

  mattr_accessor(:after_session_save) { lambda { |session| Mailer.magic_link(session).deliver_now } }

  CookieDeprecation = ActiveSupport::Deprecation.new("0.8", "passwordless")
end
