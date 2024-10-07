<p align='center'>
  <img src='https://s3.brnbw.com/Passwordless-title-gaIVkX0sPg.svg' alt='Passwordless' />
  <br />
  <br />
</p>

[![CI](https://github.com/mikker/passwordless/actions/workflows/ci.yml/badge.svg)](https://github.com/mikker/passwordless/actions/workflows/ci.yml) [![Rubygems](https://img.shields.io/gem/v/passwordless.svg)](https://rubygems.org/gems/passwordless) [![codecov](https://codecov.io/gh/mikker/passwordless/branch/master/graph/badge.svg)](https://codecov.io/gh/mikker/passwordless)

Add authentication to your Rails app without all the icky-ness of passwords. _Magic link_ authentication, if you will. We call it _passwordless_.

- [Installation](#installation)
  - [Upgrading](#upgrading)
- [Usage](#usage)
  - [Getting the current user, restricting access, the usual](#getting-the-current-user-restricting-access-the-usual)
  - [Providing your own templates](#providing-your-own-templates)
  - [Registering new users](#registering-new-users)
  - [URLs and links](#urls-and-links)
  - [Route constraints](#route-constraints)
- [Configuration](#configuration)
  - [Delivery method](#delivery-method)
  - [Token generation](#token-generation)
  - [Timeout and Expiry](#timeout-and-expiry)
  - [Redirection after sign-in](#redirection-after-sign-in)
  - [Looking up the user](#looking-up-the-user)
- [Test helpers](#test-helpers)
- [Security considerations](#security-considerations)
- [Alternatives](#alternatives)
- [License](#license)

## Installation

Add to your bundle and copy over the migrations:

```sh
$ bundle add passwordless
$ bin/rails passwordless_engine:install:migrations
```

### Upgrading

See [Upgrading to Passwordless 1.0](docs/upgrading_to_1_0.md) for more details.

## Usage

Passwordless creates a single model called `Passwordless::Session`, so it doesn't come with its own user model. Instead, it expects you to provide one, with an email field in place. If you don't yet have a user model, check out the wiki on [creating the user model](https://github.com/mikker/passwordless/wiki/Creating-the-user-model).

Enable Passwordless on your user model by pointing it to the email field:

```ruby
class User < ApplicationRecord
  # your other code..

  passwordless_with :email # <-- here! this needs to be a column in `users` table

  # more of your code..
end
```

Then mount the engine in your routes:

```ruby
Rails.application.routes.draw do
  passwordless_for :users

  # other routes
end
```

### Getting the current user, restricting access, the usual

Passwordless doesn't give you `current_user` automatically. Here's how you could add it:

```ruby
class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers # <-- This!

  # ...

  helper_method :current_user

  private

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def require_user!
    return if current_user
    save_passwordless_redirect_location!(User) # <-- optional, see below
    redirect_to root_path, alert: "You are not worthy!"
  end
end
```

Et voilà:

```ruby
class VerySecretThingsController < ApplicationController
  before_action :require_user!

  def index
    @things = current_user.very_secret_things
  end
end
```

### Providing your own templates

To make Passwordless look like your app, override the bundled views by adding your own. You can manually copy the specific views that you need or copy them to your application with `rails generate passwordless:views`.

Passwordless has 2 action views and 1 mailer view:

```sh
# the form where the user inputs their email address
app/views/passwordless/sessions/new.html.erb
# the form where the user inputs their just received token
app/views/passwordless/sessions/show.html.erb
# the email with the token and magic link
app/views/passwordless/mailer/sign_in.text.erb
```

See [the bundled views](https://github.com/mikker/passwordless/tree/master/app/views/passwordless).

### Registering new users

Because your `User` record is like any other record, you create one like you normally would. Passwordless provides a helper method to sign in the created user after it is saved – like so:

```ruby
class UsersController < ApplicationController
  include Passwordless::ControllerHelpers # <-- This!
  # (unless you already have it in your ApplicationController)

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in(create_passwordless_session(@user)) # <-- This!
      redirect_to(@user, flash: { notice: 'Welcome!' })
    else
      render(:new)
    end
  end

  # ...
end
```

### URLs and links

By default, Passwordless uses the resource name given to `passwordless_for` to generate its routes and helpers.

```ruby
passwordless_for :users
  # <%= users_sign_in_path %> # => /users/sign_in

passwordless_for :users, at: '/', as: :auth
  # <%= auth_sign_in_path %> # => /sign_in
```

Also be sure to
[specify ActionMailer's `default_url_options.host`](http://guides.rubyonrails.org/action_mailer_basics.html#generating-urls-in-action-mailer-views) and tell the routes as well:

```ruby
# config/application.rb for example:
config.action_mailer.default_url_options = {host: "www.example.com"}
routes.default_url_options[:host] ||= "www.example.com"
```

Note as well that `passwordless_for` accepts a custom controller. One possible application of this
is to add a `before_action` that redirects authenticated users from the sign-in routes, as in this example:


```ruby
# config/routes.rb
passwordless_for :users, controller: "sessions"
```

```ruby
# app/controllers/sessions_controller.rb

class SessionsController < Passwordless::SessionsController
  before_action :require_unauth!, only: %i[new show]

  private

  def require_unauth!
    return unless current_user
    redirect_to("/", notice: "You are already signed in.")
  end
end
```

### Route constraints

With [constraints](https://guides.rubyonrails.org/routing.html#request-based-constraints) you can restrict access to certain routes.
Passwordless provides `Passwordless::Constraint` and it's negative counterpart `Passwordless::ConstraintNot` for this purpose.

To limit a route to only authenticated `User`s:

```ruby
constraints Passwordless::Constraint.new(User) do
  # ...
end
```

The constraint takes a second `if:` argument, that expects a block and is passed the `authenticatable` record, (ie. `User`):

```ruby
constraints Passwordless::Constraint.new(User, if: -> (user) { user.email.include?("john") }) do
  # ...
end
```

The negated version has the same API but with the opposite result, ie. ensuring authenticated user **don't** have access:

```ruby
constraints Passwordless::ConstraintNot.new(User) do
  get("/no-users-allowed", to: "secrets#index")
end
```

## Configuration

To customize Passwordless, create a file `config/initializers/passwordless.rb`.

The default values are shown below. It's recommended to only include the ones that you specifically want to modify.

```ruby
Passwordless.configure do |config|
  config.default_from_address = "CHANGE_ME@example.com"
  config.parent_controller = "ApplicationController"
  config.parent_mailer = "ActionMailer::Base"
  config.restrict_token_reuse = true # Can a token/link be used multiple times?
  config.token_generator = Passwordless::ShortTokenGenerator.new # Used to generate magic link tokens.

  config.expires_at = lambda { 1.year.from_now } # How long until a signed in session expires.
  config.timeout_at = lambda { 10.minutes.from_now } # How long until a token/magic link times out.

  config.redirect_back_after_sign_in = true # When enabled the user will be redirected to their previous page, or a page specified by the `destination_path` query parameter, if available.
  config.redirect_to_response_options = {} # Additional options for redirects.
  config.success_redirect_path = '/' # After a user successfully signs in
  config.failure_redirect_path = '/' # After a sign in fails
  config.sign_out_redirect_path = '/' # After a user signs out

  config.paranoid = false # Display email sent notice even when the resource is not found.

  config.after_session_confirm = ->(session) {} # Called after a session is confirmed.
end
```

### Delivery method

By default, Passwordless sends emails. See [Providing your own templates](#providing-your-own-templates). If you need to customize this further, you can do so in the `after_session_save` callback.

In `config/initializers/passwordless.rb`:

```ruby
Passwordless.configure do |config|
  config.after_session_save = lambda do |session, request|
    # Default behavior is
    # Passwordless::Mailer.sign_in(session).deliver_now

    # You can change behavior to do something with session model. For example,
    # SmsApi.send_sms(session.authenticatable.phone_number, session.token)
  end
end
```

## After Session Confirmation Hook
The after_session_confirm hook is called automatically after a successful session confirmation. It receives the request and session objects as arguments, which you can use to access the authenticated user (via session.authenticatable) and perform any necessary operations.

You can configure the after_session_confirm hook in your Passwordless configuration:

```ruby
Passwordless.configure do |config|
  # ... other configuration options ...

  config.after_session_confirm = ->(session, request) {
    # Your custom logic here
    user = session.authenticatable
    user.update(email_verified: true)
    user.update(last_login_ip: request.remote_ip)
  }
end
```

### Token generation

By default Passwordless generates short, 6-digit, alpha numeric tokens. You can change the generator using `Passwordless.config.token_generator` to something else that responds to `call(session)` eg.:

```ruby
Passwordless.configure do |config|
  config.token_generator = lambda do |session|
    "probably-stupid-token-#{session.user_agent}-#{Time.current}"
  end
end
```

Passwordless will keep generating tokens until it finds one that hasn't been used yet. So be sure to use some kind of method where matches are unlikely.

### Timeout and Expiry

The _timeout_ is the time by which the generated token and magic link is invalidated. After this the token cannot be used to sign in to your app and the user will need to request a new token.

The _expiry_ is the expiration time of the session of a logged in user. Once this is expired, the user is signed out.

**Note:** Passwordless' session relies on Rails' own session and so will never live longer than that.

To configure your Rails session, in `config/initializers/session_store.rb`:

```ruby
Rails.application.config.session_store :cookie_store,
  expire_after: 1.year,
  # ...
```

### Redirection after sign-in

By default Passwordless will redirect back to where the user wanted to go _if_ it knows where that is -- so you'll have to help it. `Passwordless::ControllerHelpers` provide a method:

```ruby
class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers # <-- Probably already have this!

  # ...

  def require_user!
    return if current_user
    save_passwordless_redirect_location!(User) # <-- this one!
    redirect_to root_path, alert: "You are not worthy!"
  end
end
```

This can also be turned off with `Passwordless.config.redirect_back_after_sign_in = false`.

### Looking up the user

By default Passwordless uses the `passwordless_with` column to _case insensitively_ fetch the user resource.

You can override this by defining a class method `fetch_resource_for_passwordless` in your user model. This method will be called with the down-cased, stripped `email` and should return an `ActiveRecord` instance.

```ruby
class User < ApplicationRecord
  def self.fetch_resource_for_passwordless(email)
    find_or_create_by(email: email)
  end
end
```

## Test helpers

To help with testing, a set of test helpers are provided.

If you are using RSpec, add the following line to your `spec/rails_helper.rb`:

```ruby
require "passwordless/test_helpers"
```

If you are using TestUnit, add this line to your `test/test_helper.rb`:

```ruby
require "passwordless/test_helpers"
```

Then in your controller, request, and system tests/specs, you can utilize the following methods:

```ruby
passwordless_sign_in(user) # signs you in as a user
passwordless_sign_out # signs out user
```

## Security considerations

There's no reason that this approach should be less secure than the usual username/password combo. In fact this is most often a more secure option, as users don't get to choose the horrible passwords they can't seem to stop using. In a way, this is just the same as having each user go through "Forgot password" on every login.

But be aware that when everyone authenticates via emails, the way you send those mails becomes a weak spot. Email services usually provide a log of all the mails you send so if your email delivery provider account is compromised, every user in the system is as well. (This is the same for "Forgot password".) [Reddit was once compromised](https://thenextweb.com/hardfork/2018/01/05/reddit-bitcoin-cash-stolen-hack/) using this method.

Ideally you should set up your email provider to not log these mails. And be sure to turn on non-SMS 2-factor authentication if your provider supports it.

## Alternatives

- [OTP JWT](https://github.com/stas/otp-jwt) -- Passwordless JSON Web Tokens

## License

MIT
