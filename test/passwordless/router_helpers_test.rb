# frozen_string_literal: true

require "test_helper"

module Passwordless
  class RouterHelpersTest < ActionDispatch::IntegrationTest
    test("map sign in for user") do
      defaults = {
        authenticatable: "user",
        resource: "users"
      }

      # GET /:passwordless_for/sign_in
      assert_recognizes(
        {controller: "passwordless/sessions", action: "new"}.merge(defaults),
        {method: :get, path: "/users/sign_in"},
        defaults
      )

      # POST /:passwordless_for/sign_in
      assert_recognizes(
        {controller: "passwordless/sessions", action: "create"}.merge(defaults),
        {method: :post, path: "/users/sign_in", params: {passwordless: {email: "a@a"}}},
        defaults
      )

      # GET /:passwordless_for/sign_in/:id/:token
      assert_recognizes(
        {controller: "passwordless/sessions", action: "confirm", id: "123", token: "abc"}.merge(defaults),
        {method: :get, path: "/users/sign_in/123/abc"},
        defaults
      )

      # PATCH /:passwordless_for/sign_in/:id
      assert_recognizes(
        {controller: "passwordless/sessions", action: "update", id: "123"}.merge(defaults),
        {method: :patch, path: "/users/sign_in/123"},
        defaults
      )

      # DELETE /:passwordless_for/sign_out
      assert_recognizes(
        {controller: "passwordless/sessions", action: "destroy"}.merge(defaults),
        {method: :delete, path: "/users/sign_out"},
        defaults
      )

      # GET /:passwordless_for/sign_out
      assert_recognizes(
        {controller: "passwordless/sessions", action: "destroy"}.merge(defaults),
        {method: :get, path: "/users/sign_out"},
        defaults
      )
    end

    test("map sign in for admin") do
      defaults = {
        authenticatable: "admin",
        resource: "admins"
      }

      # GET /:passwordless_for/sign_in
      assert_recognizes(
        {controller: "passwordless/sessions", action: "new"}.merge(defaults),
        {method: :get, path: "/admins/sign_in"},
        defaults
      )

      # POST /:passwordless_for/sign_in
      assert_recognizes(
        {controller: "passwordless/sessions", action: "create"}.merge(defaults),
        {method: :post, path: "/admins/sign_in", params: {passwordless: {email: "a@a"}}},
        defaults
      )

      # GET /:passwordless_for/sign_in/:id/:token
      assert_recognizes(
        {controller: "passwordless/sessions", action: "confirm", id: "123", token: "abc"}.merge(defaults),
        {method: :get, path: "/admins/sign_in/123/abc"},
        defaults
      )

      # PATCH /:passwordless_for/sign_in/:id
      assert_recognizes(
        {controller: "passwordless/sessions", action: "update", id: "123"}.merge(defaults),
        {method: :patch, path: "/admins/sign_in/123"},
        defaults
      )

      # DELETE /:passwordless_for/sign_out
      assert_recognizes(
        {controller: "passwordless/sessions", action: "destroy"}.merge(defaults),
        {method: :delete, path: "/admins/sign_out"},
        defaults
      )

      # GET /:passwordless_for/sign_out
      assert_recognizes(
        {controller: "passwordless/sessions", action: "destroy"}.merge(defaults),
        {method: :get, path: "/admins/sign_out"},
        defaults
      )
    end
  end
end
