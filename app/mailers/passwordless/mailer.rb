# frozen_string_literal: true

module Passwordless
  # The mailer responsible for sending Passwordless' mails.
  class Mailer < Passwordless.config.parent_mailer.constantize
    default from: Passwordless.config.default_from_address

    # Sends a token and a magic link
    #
    # @param session [Session] An instance of Passwordless::Session
    # @param token [String] The token in plaintext. Falls back to `session.token` hoping it
    # is still in memory (optional)
    def sign_in(session, token = nil)
      @token = token || session.token
      @magic_link = url_for(
        {
          controller: "passwordless/sessions",
          action: "confirm",
          id: session.id,
          token: token,
          authenticatable: "user",
          resource: "users"
        }
      )
      email_field = session.authenticatable.class.passwordless_email_field

      mail(
        to: session.authenticatable.send(email_field),
        subject: I18n.t("passwordless.mailer.sign_in.subject")
      )
    end
  end
end
