# frozen_string_literal: true

module Passwordless
  # The mailer responsible for sending Passwordless' mails
  class Mailer < ActionMailer::Base
    default from: Passwordless.default_from_address

    def magic_link(session)
      @session = session

      authenticatable_resource_name =
        @session.authenticatable_type.underscore.pluralize
      @magic_link =
        send(authenticatable_resource_name).token_sign_in_url(session.token)

      email_field = @session.authenticatable.class.passwordless_email_field
      mail(
        to: @session.authenticatable.send(email_field),
        subject: 'Your magic link ✨'
      )
    end
  end
end
