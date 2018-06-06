# 0.5.3 (2018-06-06)

- Fixed: Missing `as:` on session association `has_many` (#23)

# 0.5.2 (2018-04-24)

- Added: Include main app's routes in passwordless views

# 0.5.1 (2018-04-16)

- Fixed: Authenticatable (User) lookup is case-insentive

# 0.5.0 (2018-02-26)

- Added: Support for I18n (Thanks @mftaff)
- Fixed: Actually expire sessions (Thanks @mftaff)

# 0.4.4 (2018-01-02)

- Added: `build_passwordless_session` controller helper

# 0.4.3 (2017-12-27)

- Added: Documentation! (Thanks to @mftaff)

# 0.4.2 (2017-12-24)

- Fixed: Case-insensitive email lookup

# 0.4.1 (2017-11-27)

- Fixed: Post-sign in redirect destination is scoped to model

# 0.4.0 (2017-11-27)

- Added: Redirect to previous destination post sign in
- Added: Added `#passwordless_controller?`
- Fixed: Inherit from main app's ApplicationController

# 0.3.1 (2017-11-11)

- Fixed: Removed Gemfile.lock

# 0.3.0 (2017-11-11)

- Added: An option to provide a custom token generator
- Added: Changelog
