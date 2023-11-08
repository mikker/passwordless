require "test_helper"

class Passwordless::MailerTest < ActionMailer::TestCase
  test("sign_in") do
    user = users(:alice)
    session = Passwordless::Session.create!(authenticatable: user, token: "hello")

    email = Passwordless::Mailer.sign_in(session, "hello")

    assert_equal [user.email], email.to

    assert_match "Signing in ✨", email.subject
    assert_match /sign in: hello\n/, email.body.to_s
    assert_match %r{/sign_in/#{session.identifier}/hello}, email.body.to_s

    session = Passwordless::Session.create!(authenticatable: user)
    email = Passwordless::Mailer.sign_in(session)
    assert_equal [user.email], email.to
  end
end
