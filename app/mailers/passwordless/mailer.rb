# frozen_string_literal: true

module Passwordless
  # The mailer responsible for sending Passwordless' mails.
  class Mailer < Passwordless.config.parent_mailer.constantize
    default(from: Passwordless.config.default_from_address) if Passwordless.config.default_from_address

    # Sends a token and a magic link
    #
    # @param session [Session] An instance of Passwordless::Session
    # @param token [String] The token in plaintext. Falls back to `session.token` hoping it
    # is still in memory (optional)
    def sign_in(session, token = nil, url_options = {})
      @token = token || session.token

      @magic_link = Passwordless.context.url_for(
        session,
        action: "confirm",
        id: session.to_param,
        token: @token,
        **url_options,
        **default_url_options
      )

      email_field = session.authenticatable.class.passwordless_email_field

      mail(
        to: session.authenticatable.send(email_field),
        subject: I18n.t("passwordless.mailer.sign_in.subject")
      )
    end

    # sends an email when user attempts to login with unknown address
    #
    # @param session [Session] An instance of Passwordless::Session
    def unknown_address(session)
      email_field = session.authenticatable.class.passwordless_email_field
      @email = session.authenticatable.send(email_field)

      mail(
        to: @email,
        subject: I18n.t("passwordless.mailer.unknown_address.subject")
      )
    end
  end
end
