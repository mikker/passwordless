# frozen_string_literal: true

require "test_helper"

module Passwordless
  class ContextTest < ActiveSupport::TestCase
    test("url_for") do
      session = Session.create!(authenticatable: users(:alice), token: "hello")
      url = Passwordless.context.url_for(session, action: "confirm", id: session.to_param, token: session.token)
      assert_match %r{/sign_in/#{session.identifier}/hello}, url
    end
  end
end
