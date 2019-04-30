$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "passwordless/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "passwordless"
  s.version     = Passwordless::VERSION
  s.authors     = ["Mikkel Malmberg"]
  s.email       = ["mikkel@brnbw.com"]
  s.homepage    = "https://github.com/mikker/passwordless"
  s.summary     = "Add authentication to your app without all the ickyness of passwords."
  # s.description = "Description of Passwordless."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1.4"
  s.add_dependency "bcrypt", "~> 3.1.11"

  s.add_development_dependency "sqlite3", "~> 1.4.1"
  s.add_development_dependency "yard"
  s.add_development_dependency "standard"
end
