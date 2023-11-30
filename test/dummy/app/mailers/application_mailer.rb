# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "from@example.org"
  layout "mailer"

  def default_url_options
    { host: "www.example.org" }
  end
end
