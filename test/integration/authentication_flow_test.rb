require "test_helper"
require "capybara/rails"

class AuthenticationFlowTest < ActionDispatch::SystemTestCase
  include ActionMailer::TestHelper

  driven_by :rack_test

  fixtures :users

  test("failed access") do
    visit "/secret"
    assert_content "Not worthy!"
  end

  test("sign in with token redirects to protected resource") do
    alice = users(:alice)

    visit "/secret"
    click_link "Sign in"

    assert_emails(1) do
      fill_in "passwordless[email]", with: alice.email
      click_button "Sign in"
    end

    assert_content "We've sent you an email"

    email = ActionMailer::Base.deliveries.last
    assert_equal alice.email, email.to.first
    token = email.body.match(%r{http://.*/sign_in/[A-Za-z0-9\-]+/(\w+)})[1]

    fill_in "passwordless[token]", with: token
    click_button "Confirm"

    assert_equal "/secret", current_path
    assert_content "shhhh! secrets!"
  end

  test("sign in with magic link redirects to success path") do
    alice = users(:alice)

    visit "/secret"
    click_link "Sign in"

    assert_emails(1) do
      fill_in "passwordless[email]", with: alice.email
      click_button "Sign in"
    end

    assert_content "We've sent you an email"

    email = ActionMailer::Base.deliveries.last
    assert_equal alice.email, email.to.first
    magic_link = email.body.to_s.scan(%r{http://.*/sign_in/[a-z0-9\-]+/\w+}).at(0)

    visit magic_link

    assert_equal "/", current_path
    assert_content "Current user: #{alice.email}"
  end
end
