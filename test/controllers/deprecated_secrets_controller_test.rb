# frozen_string_literal: true

require "test_helper"

class DeprecatedSecretsControllerTest < ActionDispatch::IntegrationTest
  def create_session_for(user)
    Passwordless::Session.create!(
      authenticatable: user,
      remote_addr: "yes",
      user_agent: "James Bond"
    )
  end

  def cookie_key(authenticatable_class)
    DeprecatedSecretsController.new.send(:cookie_key, authenticatable_class)
  end

  def login(passwordless_session)
    post "/deprecated_fake_login", params: {
      authenticatable_type: passwordless_session.authenticatable_type,
      authenticatable_id: passwordless_session.authenticatable_id,
    }
  end

  test "authenticate_by_cookies" do
    user = User.create(email: "foo@example.com")
    passwordless_session = create_session_for(user)
    login(passwordless_session)

    get "/deprecated_secret"
    assert_equal 200, status
  end
end
