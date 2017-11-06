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

Passwordless creates a single model called `Passwordless::Session`.

Mount the `passwordless` engine in your routes:

```ruby
Rails.application.routes.draw do
  passwordless_for :users

  # other routes
end
```

And specify which field on your user record is the email field with:

```ruby
class User < ApplicationRecord
  passwordless_with :email
end
```

## Providing your own templates

Override `passwordless`' bundled views by adding your own. `passwordless` has 2 action views and 1 mailer view:

```
# the form where the user inputs their email address
app/views/passwordless/sessions/new.html.erb
# shown after a user requests a magic link
app/views/passwordless/sessions/create.html.erb
# the mail with the magic link that gets sent
app/views/passwordless/mailer/magic_link.text.erb
```

See [the bundled views](https://github.com/mikker/passwordless/tree/master/app/views/passwordless).

# License

MIT
