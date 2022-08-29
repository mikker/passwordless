require 'rails/generators'

module Passwordless
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../app/views/passwordless', __dir__)

      def install
        copy_file 'mailer/magic_link.text.erb', 'app/views/passwordless/mailer/magic_link.text.erb'
        copy_file 'sessions/new.html.erb', 'app/views/passwordless/sessions/new.html.erb'
        copy_file 'sessions/create.html.erb', 'app/views/passwordless/sessions/create.html.erb'
      end
    end
  end
end
