<p align='center'>
  <img src='https://s3.brnbw.com/Passwordless-title-gaIVkX0sPg.svg' alt='Passwordless' />
  <br />
  <br />
</p>

[![Travis](https://travis-ci.org/mikker/passwordless.svg?branch=master)](https://travis-ci.org/mikker/passwordless) [![Rubygems](https://img.shields.io/gem/v/passwordless.svg)](https://rubygems.org/gems/passwordless) [![codecov](https://codecov.io/gh/mikker/passwordless/branch/master/graph/badge.svg)](https://codecov.io/gh/mikker/passwordless)

Add authentication to your Rails app without all the icky-ness of passwords.

---

## Table of Contents

* [Installation](#installation)
* [Usage](#usage)
     * [Getting the current user, restricting access, the usual](#getting-the-current-user-restricting-access-the-usual)
     * [Providing your own templates](#providing-your-own-templates)
     * [Overrides](#overrides)
     * [Registering new users](#registering-new-users)
     * [Generating tokens](#generating-tokens)
     * [Token and Session Expiry](#token-and-session-expiry)
     * [Redirecting back after sign-in](#redirecting-back-after-sign-in)
     * [URLs and links](#urls-and-links)
     * [Customize the way to send magic link](#customize_the_way_to_send_magic_link)
     * [E-mail security](#e-mail-security)
* [License](#license)

## Installation

Add the `passwordless` gem to your `Gemfile`:

```ruby
gem 'passwordless'
```

Install it and copy over the migrations:

```sh
$ bundle
$ bin/rails passwordless:install:migrations
```

## Usage

Passwordless creates a single model called `Passwordless::Session`. It doesn't come with its own `User` model, it expects you to create one, eg.:

```
$ bin/rails generate model User email
```

Then specify which field on your `User` record is the email field with:

```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  passwordless_with :email # <-- here!
end
```

Finally, mount the engine in your routes:

```ruby
Rails.application.routes.draw do
  passwordless_for :users

  # other routes
end
```

### Getting the current user, restricting access, the usual

Passwordless doesn't give you `current_user` automatically -- it's dead easy to add it though:

```ruby
class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers # <-- This!

  # ...

  helper_method :current_user

  private

  def current_user
    @current_user ||= authenticate_by_cookie(User)
  end

  def require_user!
    return if current_user
    redirect_to root_path, flash: {error: 'You are not worthy!'}
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

Override `passwordless`' bundled views by adding your own. `passwordless` has 2 action views and 1 mailer view:

```sh
# the form where the user inputs their email address
app/views/passwordless/sessions/new.html.erb
# shown after a user requests a magic link
app/views/passwordless/sessions/create.html.erb
# the mail with the magic link that gets sent
app/views/passwordless/mailer/magic_link.text.erb
```

See [the bundled views](https://github.com/mikker/passwordless/tree/master/app/views/passwordless).

### Overrides

By default `passwordless` uses the `passwordless_with` column you specify in the model to case insensitively fetch the resource during authentication. You can override this and provide your own customer fetcher by defining a class method `fetch_resource_for_passwordless` in your passwordless model. The method will be supplied with the downcased email and should return an `ActiveRecord` instance of the model.

Example time:

Let's say we would like to fetch the record and if it doesn't exist, create automatically.

```ruby
class User < ApplicationRecord
  def self.fetch_resource_for_passwordless(email)
    find_or_create_by(email: email)
  end
end
```

### Registering new users

Because your `User` record is like any other record, you create one like you normally would. Passwordless provides a helper method you can use to sign in the created user after it is saved like so:

```ruby
class UsersController < ApplicationController
  include Passwordless::ControllerHelpers # <-- This!
  #  (unless you already have it in your ApplicationController)

  def create
    @user = User.new user_params

    if @user.save
      sign_in @user # <-- And this!
      redirect_to @user, flash: {notice: 'Welcome!'}
    else
      render :new
    end
  end

  # ...
end
```

### Generating tokens

By default Passwordless generates tokens using Rails' `SecureRandom.urlsafe_base64` but you can change that by setting `Passwordless.token_generator` to something else that responds to `call(session)` eg.:

```ruby
Passwordless.token_generator = -> (session) {
  "probably-stupid-token-#{session.user_agent}-#{Time.current}"
}
```

Session is going to keep generating tokens until it finds one that hasn't been used yet. So be sure to use some kind of method where matches are unlikely.

### Token and Session Expiry

Token timeout is the time by which the sign in token is invalidated. Post the timeout, the token cannot be used to sign-in to the app and the user would need to request it again.

Session expiry is the expiration time of the session of a logged in user. Once this is expired, user would need to log back in to create a new session.

#### Token timeout

By default, sign in tokens generated by Passwordless are made invalid after `1.hour` from the time they are generated. If you wish you can override this and supply your custom Proc function that will return a valid datetime object. Make sure the generated time is in the future.

> Make sure to use a `.call`able object, like a proc or lambda as it will be called everytime a session is created.

```ruby
Passwordless.timeout_at = lambda { 2.hours.from_now }
```

#### Session Expiry

Session expiry is the time when the actual session is itself expired, i.e. users will be logged out and has to sign back in post this expiry time. By default, sessions are valid for `1.year` from the time they are generated. You can override by providing your custom Proc function that returns a datetime object.

> Make sure to use a `.call`able object, like a proc or lambda as it will be called everytime a session is created.

```ruby
Passwordless.expires_at = lambda { 24.hours.from_now }
```

### Redirecting back after sign-in

By default Passwordless will redirect back to where the user wanted to go **if** it knows where that is, so you'll have to help it. `Passwordless::ControllerHelpers` provide a method for this:

```ruby
class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers # <-- Probably already have this!

  # ...

  def require_user!
    return if current_user
    save_passwordless_redirect_location!(User) # <-- here we go!
    redirect_to root_path, flash: {error: 'You are not worthy!'}
  end
end
```

This can be turned off with `Passwordless.redirect_back_after_sign_in = false` but if you just don't save the previous destination, you'll be fine.

### URLs and links

By default, Passwordless uses the resource name given to `passwordless_for` to generate its routes and helpers.

```ruby
passwordless_for :users
  # <%= users.sign_in_path %> # => /users/sign_in

passwordless_for :users, at: '/', as: :auth
  # <%= auth.sign_in_path %> # => /sign_in
```

Also be sure to [specify ActionMailer's `default_url_options.host`](http://guides.rubyonrails.org/action_mailer_basics.html#generating-urls-in-action-mailer-views).


### Customize the way to send magic link

By default, magic link will send by email. You can customize this method. For example, you can send magic link via SMS.

config/initializers/passwordless.rb

```
Passwordless.after_session_save = lambda do |session|
  # Default behavior is
  # Mailer.magic_link(session).deliver_now

  # You can change behavior to do something with session model. For example,
  # session.authenticatable.send_sms
end
```

You can access user model through authenticatable.


### E-mail security

There's no reason that this approach should be less secure than the usual username/password combo. In fact this is most often a more secure option, as users don't get to choose the weak passwords they still use. In a way this is just the same as having each user go through "Forgot password" on every login.

But be aware that when everyone authenticates via emails you send, the way you send those mails becomes a weak spot. Email services usually provide a log of all the mails you send so if your app's account is compromised, every user in the system is as well. (This is the same for "Forgot password".) [Reddit was compromised](https://thenextweb.com/hardfork/2018/01/05/reddit-bitcoin-cash-hack/) using this method.

Ideally you should set up your email provider to not log these mails. And be sure to turn on 2-factor auth if your provider supports it.

# License

MIT
