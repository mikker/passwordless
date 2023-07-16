# frozen_string_literal: true

module Passwordless
  # The mailer responsible for sending Passwordless' mails.
  class Mailer < Passwordless.config.parent_mailer.constantize
    default from: Passwordless.config.default_from_address

    # Sends a magic link (secret token) email.
    # @param session [Session] A Passwordless Session
    # @param token [String] The token in plaintext. Falls back to `session.token` hoping it
    # is still in memory (optional)
    def magic_link(session, token = nil)
      @session = session
      @token = token || session.token

      @magic_link = send(:"#{session.authenticatable_type.downcase.pluralize}_token_sign_in_url", token)

      email_field = @session.authenticatable.class.passwordless_email_field
      mail(
        to: @session.authenticatable.send(email_field),
        subject: I18n.t("passwordless.mailer.subject")
      )
    end
  end
end
