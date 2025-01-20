# Upgrading to Passwordless 1.0

**This major release of Passwordless changes a lot of things and it is almost guaranteed that you will need to change your code to upgrade to this version.**

Note that there is no _need_ to upgrade. The previous versions of Passwordless will continue to work for the foreseeable future.

From 1.0 the flow is:

1. User enters email
1. User is presented with a token input page
1. User enters token OR clicks link in email
1. User is signed in

## 1. Upgrade your database

If you're already running Passwordless, you'll need to update your database schema.

```sh
$ bin/rails g migration UpgradePasswordless
```

```ruby
class UpgradePasswordless < ActiveRecord::Migration[7.0]
  def change
    # Encrypted tokens
    add_column(:passwordless_sessions, :token_digest, :string)
    add_index(:passwordless_sessions, :token_digest)
    remove_column(:passwordless_sessions, :token, :string, null: false)
    # UUID
    add_column(:passwordless_sessions, :identifier, :string)
    add_index(:passwordless_sessions, :identifier, unique: true)

    # Remove PII
    remove_column(:passwordless_sessions, :user_agent, :string, null: false)
    remove_column(:passwordless_sessions, :remote_addr, :string, null: false)
  end
end
```

## 2. Move configuration to `Passwordless.config`

Passwordless is now configured like this. In `config/initializers/passwordless.rb`:

```ruby
Passwordless.configure do |config|
  config.default_from_address = "admin@yourthing.app"
end
```

## 3. Update your views (if you have customized them)

The existing views have changed and a new one has been added. Regenerate them using `rails generate passwordless:views`.

## 4. Un-isolated namespace

Passwordless no longer [_isolates namespace_](https://guides.rubyonrails.org/engines.html#routes).

1.  Change all your links with eg. `users.sign_in_path` to `users_sign_in_path`
1.  Change all links with `main_app.whatever_path` to just `whatever_path`

## 5. Stop collecting PII

Passwordless no longer collects users' IP addresses. If you need this information, you can
add it to your `after_session_save` callback.

## 6. Encrypted tokens

Tokens are encrypted at rest in the database. This means that any tokens that were generated with a previous version of Passwordless will no longer work.

## 7. Remove calls to deprecated methods and helpers

Removes `authenticate_by_cookie` and `upgrade_passwordless_cookie` from controller helpers.
