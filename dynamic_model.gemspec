$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'dynamic_model/version_number'

Gem::Specification.new do |s|
  s.name          = 'dynamic_model'
  s.version       = DynamicModel::VERSION
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Add dynamic attributes, defined on DB, to models."
  s.description   = s.summary
  s.homepage      = 'https://github.com/rmolival'
  s.authors       = ['Roberto M. Oliva']
  s.email         = 'floyd303@gmail.com'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activerecord', ['>= 3.0', '< 4.0']
  s.add_dependency 'activesupport', ['>= 3.0', '< 4.0']

  s.add_development_dependency 'rake', '~> 10.1.1'
  s.add_development_dependency 'shoulda', '~> 3.5'
  # s.add_development_dependency 'shoulda-matchers', '~> 1.5' # needed for ActiveRecord < 4
  s.add_development_dependency 'ffaker',  '>= 1.15'
  #s.add_development_dependency 'railties', ['>= 3.0', '< 5.0']
  s.add_development_dependency 'rspec-rails', '~> 2.14'
  s.add_development_dependency 'generator_spec'
  s.add_development_dependency 'database_cleaner', '~> 1.2'

  # JRuby support for the test ENV
  unless defined?(JRUBY_VERSION)
    #s.add_development_dependency 'sqlite3', '~> 1.2'
    s.add_development_dependency 'mysql2', '~> 0.3'
    #s.add_development_dependency 'pg', '~> 0.17'
  else
    #s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3'
    #s.add_development_dependency 'activerecord-jdbcpostgresql-adapter', '~> 1.3'
    #s.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.3'
  end
end