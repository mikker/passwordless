# frozen_string_literal: true

require "active_support"
require "passwordless/errors"
require "passwordless/engine"
require "passwordless/url_safe_base_64_generator"

# The main Passwordless module
module Passwordless
  mattr_accessor(:parent_mailer) { "ActionMailer::Base" }
  mattr_accessor(:default_from_address) { "CHANGE_ME@example.com" }
  mattr_accessor(:token_generator) { UrlSafeBase64Generator.new }
  mattr_accessor(:restrict_token_reuse) { false }
  mattr_accessor(:redirect_back_after_sign_in) { true }
  mattr_accessor(:mounted_as) { :configured_when_mounting_passwordless }

  mattr_accessor(:expires_at) { lambda { 1.year.from_now } }
  mattr_accessor(:timeout_at) { lambda { 1.hour.from_now } }
  mattr_accessor(:success_redirect_path) { "/" }
  mattr_accessor(:failure_redirect_path) { "/" }
  mattr_accessor(:sign_out_redirect_path) { "/" }

  mattr_accessor(:after_session_save) do
    lambda { |session, _request| Mailer.magic_link(session).deliver_now }
  end

  CookieDeprecation = ActiveSupport::Deprecation.new("0.9", "passwordless")
  SessionValidDeprecation = ActiveSupport::Deprecation.new("0.9", "passwordless")
end
