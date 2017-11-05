module Passwordless
  class Mailer < ActionMailer::Base
    default from: 'from@example.com'

    def magic_link(session)
      @session = session

      email_field = @session.authenticatable.class.passwordless_email_field
      mail to: @session.authenticatable.send(email_field), subject: "Your magic link ✨"
    end
  end
end
