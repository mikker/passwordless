# Passwordless

<img src='https://travis-ci.org/mikker/passwordless.svg?branch=master' alt='Build status' />

Add authentication to your Rails app without all the icky-ness of passwords.

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

Passwordless creates a single model called `Passwordless::Session`. It doesn't come with its own `User` model, it expects you to create one, eg.:

```
$ bin/rails generate model User email
```

Then specify which field on your `User` record is the email field with:

```ruby
class User < ApplicationRecord
  passwordless_with :email
end
```

Finally, mount the engine in your routes:

```ruby
Rails.application.routes.draw do
  passwordless_for :users

  # other routes
end
```

## Getting the current user, restricting access, the usual

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

## Providing your own templates

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

## Registering new users

Because your `User` record is just any other record, you just create one like you normally would. Passwordless provides a helper method you can use to sign in the created user after it is saved like so:

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

Et voilá:

```ruby
class VerySecretThingsController < ApplicationController
  before_filter :require_user!
  
  def index
    @things = current_user.very_secret_things
  end
end
```

# License

MIT
