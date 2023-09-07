# Changelog

## Unreleased

### Breaking changes

This major release of Passwordless changes a lot of things and it is almost guaranteed that you will need to change your code to upgrade to this version.

**Note** that there is no _need_ to upgrade. The previous versions of Passwordless will continue to work for the foreseeable future.

The flow is now:

1. User enters email
1. User is presented with a token input page
1. User enters token OR clicks link in email
1. User is signed in

#### 1. Upgrade your database

If you're already running Passwordless, you'll need to update your database schema.

```sh
$ bin/rails g migration UpgradePassswordless
```

```ruby
class UpgradePassswordless < ActiveRecord::Migration[7.0]
  def change
    # Encrypted tokens
    add_column(:passwordless_sessions, :token_digest, :string)
    add_index(:passwordless_sessions, :token_digest)
    remove_column(:passwordless_sessions, :token, :string, null: false)

    # Remove PII
    remove_column(:passwordless_sessions, :user_agent, :string, null: false)
    remove_column(:passwordless_sessions, :remote_addr, :string, null: false)
  end
end
```

#### 2. Move configuration to `Passwordless.config`

Passwordless is now configured like this. In `config/initializers/passwordless.rb`:

```ruby
Passwordless.configure do |config|
  config.default_from_address = "admin@yourthing.app"
end
```

#### 3. Update your views (if you have customized them)

The existing views have changed and a new one has been added. Regenerate them using `rails generate passwordless:views`.

#### 4. Un-isolated namespace

Passwordless no longer [_isolates namespace_](https://guides.rubyonrails.org/engines.html#routes).

1.  Change all your links with eg. `users.sign_in_path` to `users_sign_in_path`
1.  Change all links with `main_app.whatever_path` to just `whatever_path`

#### 5. Stop collecting PII

Passwordless no longer collects users' IP addresses. If you need this information, you can
add it to your `after_session_save` callback.

#### 6. Encrypted tokens

Tokens are now stored encrypted in the database. This means that any tokens that were generated with a previous version of Passwordless will no longer work.

#### 7. Remove deprecated methods and helpers

Removes `authenticate_by_cookie` and `upgrade_passwordless_cookie` from controller helpers.

### Added

- Added an option to set a custom controller for `passwordless_for` routes ([#152](https://github.com/mikker/passwordless/pull/152))

### Changed

- Tokens are now encrypted in the database ([#145](https://github.com/mikker/passwordless/pull/145))
- Un-isolate namespace ([#146](https://github.com/mikker/passwordless/pull/146))
- Move configuration to `Passwordless.config` ([#155](https://github.com/mikker/passwordless/pull/155))

### Removed

- Deprecated methods and helpers ([#147](https://github.com/mikker/passwordless/pull/147))
- Collection of PII (IP address, User Agent) ([#153](https://github.com/mikker/passwordless/pull/153))

### Fixed

- Remove reference to deleted generator file ([#149](https://github.com/mikker/passwordless/pull/149))
- Return early on HEAD requests ([#151](https://github.com/mikker/passwordless/pull/151))

## 0.12.0 (2023-06-16)

### Added

- Added option `redirect_to_response_options` ([#142](https://github.com/mikker/passwordless/pull/142))

### Changed

- Replaced `form_for` with `form_with` in view template ([#128](https://github.com/mikker/passwordless/pull/128))
- Added frontend validation for email presence in views ([#128](https://github.com/mikker/passwordless/pull/128))
- Always redirect magic link requests back to the sign_in page and render generic flash ([#120](https://github.com/mikker/passwordless/pull/120))

### Fixed

- Fix `Passwordless#ControllerHelpers` to be used outside controllers (#124)

## 0.11.0

### Changed

- Reset session at sign_in to protect from session fixation attacks ([#108](https://github.com/mikker/passwordless/pull/108))

### Added

- Test helpers for MiniTest and RSpec ([#90](https://github.com/mikker/passwordless/pull/90))
- Generator to copy the bundled views ([#123](https://github.com/mikker/passwordless/issues/123))

### Fixed

- Fixed support for Turbo Drive ([#116](https://github.com/mikker/passwordless/pull/116))

## 0.10.0 (2020-10-07)

### Added

- Option to customize mailer inheritance with a new configuration `parent_mailer` ([#82](https://github.com/mikker/passwordless/pull/82))

### Fixed

- Calls `strip` on passwordless field param

## 0.9.0 (2019-12-19)

### Added

- Customizable redirects ([#69](https://github.com/mikker/passwordless/pull/69))

## 0.8.2 (2019-08-30)

### Fixed

- Fixes session availability wrongly determined by _timeout_ not _expiry_ ([#61](https://github.com/mikker/passwordless/pull/61))

## 0.8.1 (2019-08-14)

### Fixed

- Fixes an issue with using a resource class not named `User` ([#58](https://github.com/mikker/passwordless/pull/58))

## 0.8.0 (2019-07-30)

### Breaking changes

This version moves from storing the session information in the `cookies` to the `session`.
Your users will therefore have to sign in again after upgrading.

To provide a smoother experience, you can use the provided session upgrade helper like this:

```ruby
def current_user
  @current_user ||=
    authenticate_by_session(User) ||
    upgrade_passwordless_cookie(User)
end
```

### Deprecations

- Deprecates `authenticate_by_cookie`, use `authenticate_by_session`.([#56](https://github.com/mikker/passwordless/pull/56))

### Added

- `restrict_token_reuse` disables session reuse ([#51](https://github.com/mikker/passwordless/pull/51))

### Changed

- Optionally pass `request` to `after_session_save` ([#49](https://github.com/mikker/passwordless/pull/49))
- Sign in via `Passwordless::Session` instead of authenticatable and store it in `session` instead of `cookies` ([#56](https://github.com/mikker/passwordless/pull/56))
- `sign_in` helper now expects a `Passwordless::Session`.

## 0.7.0 (2019-03-06)

### Added

- Option to customize callback (eg. send e-mail, sms, whatever) ([#39](https://github.com/mikker/passwordless/pull/37))

### Fixed

- Use `timeout_at` instead of `expires_at` when signing in ([#43](https://github.com/mikker/passwordless/pull/43))

## 0.6.0 (2019-01-29)

### Added

- Option to set custom expiration and timeout durations ([#37](https://github.com/mikker/passwordless/pull/37))
- Allow overriding the lookup method of the user resource ([#33](https://github.com/mikker/passwordless/pull/33))

## 0.5.4 (2018-06-22)

- Fixed: Support models using Single Table Inheritance ([#26](https://github.com/mikker/passwordless/pull/26))

## 0.5.3 (2018-06-06)

- Fixed: Missing `as:` on session association `has_many` ([#23](https://github.com/mikker/passwordless/issues/23))

## 0.5.2 (2018-04-24)

- Added: Include main app's routes in passwordless views

## 0.5.1 (2018-04-16)

- Fixed: Authenticatable (User) lookup is case-insentive

## 0.5.0 (2018-02-26)

- Added: Support for I18n (Thanks @mftaff)
- Fixed: Actually expire sessions (Thanks @mftaff)

## 0.4.4 (2018-01-02)

- Added: `build_passwordless_session` controller helper

## 0.4.3 (2017-12-27)

- Added: Documentation! (Thanks to @mftaff)

## 0.4.2 (2017-12-24)

- Fixed: Case-insensitive email lookup

## 0.4.1 (2017-11-27)

- Fixed: Post-sign in redirect destination is scoped to model

## 0.4.0 (2017-11-27)

- Added: Redirect to previous destination post sign in
- Added: Added `#passwordless_controller?`
- Fixed: Inherit from main app's ApplicationController

## 0.3.1 (2017-11-11)

- Fixed: Removed Gemfile.lock

## 0.3.0 (2017-11-11)

- Added: An option to provide a custom token generator
- Added: Changelog
