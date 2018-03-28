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
     * [Registering new users](#registering-new-users)
     * [Generating tokens](#generating-tokens)
     * [Redirecting back after sign-in](#redirecting-back-after-sign-in)
     * [URLs and links](#urls-and-links)
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

### E-mail security
When using e-mail to login users e-mail security is extremely important. If the service you use to deliver e-mails is compromised your entire app is compromised. Services like SendGrid, Mailgun etc log e-mails, and their content witch basically is the same as storing passwords in clear text. Using e-mail to send password reset links has the same vulnerability. [Reddit was compromised](https://thenextweb.com/hardfork/2018/01/05/reddit-bitcoin-cash-hack/) using this method.

Make sure that you use an e-mail service that does not log the content of the e-mails that you send with passwordless. 

# License

MIT
