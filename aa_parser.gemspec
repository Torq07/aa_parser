$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aa_parser/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aa_parser"
  s.version     = AaParser::VERSION
  s.authors     = ["Denis Presnov"]
  s.email       = ["torq07@gmail.com"]
  s.homepage    = "https://github.com/Torq07/activeadmin_parser"
  s.summary     = "Parse for activeAdmin"
  s.description = "Parser fro AA"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.1"
  s.add_dependency "activeadmin", '~> 1.0.0.pre4'

  s.add_development_dependency "sqlite3"
end
