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
  end

  test("sign_in when no token is passed") do
    user = users(:alice)
    session = Passwordless::Session.create!(authenticatable: user, token: "hello")

    email = Passwordless::Mailer.sign_in(session)

    assert_match %r{/sign_in/#{session.identifier}/hello}, email.body.to_s
  end

  test("sign in with custom controller") do
    admin = admins(:jerry)
    session = Passwordless::Session.create!(authenticatable: admin, token: "hello")

    email = Passwordless::Mailer.sign_in(session, "hello")

    assert_equal [admin.email], email.to

    assert_match "Signing in ✨", email.subject
    assert_match /sign in: hello\n/, email.body.to_s
    assert_match %r{/admins/sign_in/#{session.identifier}/hello}, email.body.to_s
  end

  test("uses default_url_options from config.action_mailer") do
    session = Passwordless::Session.create!(authenticatable: users(:alice), token: "hello")
    email = Passwordless::Mailer.sign_in(session, "hello")

    assert_match %r{www.example.com/users/sign_in/#{session.identifier}/hello}, email.body.to_s
  end

  test("uses default_url_options from mailer") do
    with_config({parent_mailer: "ApplicationMailer"}) do
      # We need to reload the mailer, because the test sets set a different
      # parent class for the mailer. This means `Passwordless::Mailer` needs
      # to be reloaded, otherwise it will still have the old parent class.
      reload_mailer!

      session = Passwordless::Session.create!(authenticatable: users(:alice), token: "hello")
      email = Passwordless::Mailer.sign_in(session, "hello")

      assert_match %r{www.example.org/users/sign_in/#{session.identifier}/hello}, email.body.to_s
    end

  ensure
    # Reload the mailer again, because the config is reset back to the default
    # after the `with_config` block.
    reload_mailer!
  end

  test("uses default from address of parent when default_from_address is nil") do
    with_config({parent_mailer: "ApplicationMailer", default_from_address: nil}) do
      reload_mailer!

      assert_equal ApplicationMailer.default.fetch(:from), Passwordless::Mailer.default.fetch(:from)
    end

  ensure
    reload_mailer!
  end
end
