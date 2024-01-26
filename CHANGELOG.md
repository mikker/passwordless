# Changelog

## 1.4.0

### Changed

- Configurable redirect paths now accept both strings and lambdas (#202)

## 1.3.0

### Changed

- The default `from` of the parent mailer won't be overridden if the `default_from_address` option is set to `nil` (#198)

### Added

- Added `paranoid` option to display the email sent notice even when the resource is not found (#196)
- Added `parent_controller` option to set the `SessionsController` parent class (#199)
- Added `only_path` param to `SystemTestCase#passwordless_sign_in` and `SystemTestCase#passwordless_sign_out` (#197)

## 1.2.0

### Added

- Added the option `combat_brute_force_attacks`, enabled everywhere but Rails.env.test (#190)

## 1.1.1

### Fixed

- Fixed url generation when custom controller is specified (#180)
- Fixed a bug in `passwordless_sign_in` (#179)

## 1.1.0

### Changed

Sessions are now referenced publicly by a random UUID instead of their primary key.

This needs a manual database migration like so:

```ruby
class AddIndentifierToPasswordlessSessions < ActiveRecord::Migration[7.1]
  def change
    add_column(:passwordless_sessions, :identifier, :string)
    add_index(:passwordless_sessions, :identifier, unique: true)
  end
end
```

- Use UUIDs as indentifiers for sessions in public (#176)

### Added

- Add default flash notice for sign out (#178)

### Fixed

- Route generation with :as option (#174)
- Test helper route generation (#174)

## 1.0.1

### Fixed

- Fix sessions/new label for attribute (#172)
- Adds `autocomplete: 'off'` to token field (#173)
- Adds sessions/show "Confirm" to locale definition (#173)

## 1.0.0 (🎉)

### Breaking changes

**This major release of Passwordless changes a lot of things and it is almost guaranteed that you will need to change your code to upgrade to this version.**

(Note that there is no _need_ to upgrade. The previous versions of Passwordless will continue to work for the foreseeable future.)

See [Upgrading to Passwordless 1.0](docs/upgrading_to_1_0.md) for more details.

### Added

- Added an option to set a custom controller for `passwordless_for` routes ([#152](https://github.com/mikker/passwordless/pull/152))
- Added `ControllerHelpers#create_passwordless_session` ([#161](https://github.com/mikker/passwordless/pull/161))

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
