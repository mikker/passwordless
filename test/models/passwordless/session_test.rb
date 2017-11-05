require 'test_helper'

module Passwordless
  class SessionTest < ActiveSupport::TestCase
    def create_session(attrs = {})
      Session.create!(attrs.reverse_merge(
        remote_addr: '0.0.0.0',
        user_agent: 'wooden box',
        authenticatable: User.create(email: 'session_test_valid@a')
      ))
    end

    test "scope: valid" do
      valid = create_session
      _expired = create_session expires_at: 1.hour.ago
      _timed_out = create_session timeout_at: 1.hour.ago

      assert_equal [valid], Session.valid.all
    end

    test "it has defaults" do
      session = Session.new
      session.validate

      refute_nil session.expires_at
      refute_nil session.timeout_at
      refute_nil session.token
    end
  end
end
