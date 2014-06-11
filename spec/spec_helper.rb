ENV["RAILS_ENV"] ||= 'test'
ENV["DB"] ||= 'mysql'

require 'active_support'
require 'active_support/core_ext'
require "rails/all"
require 'rspec/rails'
require 'rspec/autorun'
require 'shoulda/matchers'
require 'ffaker'
require 'database_cleaner'

require File.join(File.dirname(__FILE__), "..", "lib", "dynamic_model.rb")

# Conectarse a la base de datos
db_config = YAML.load_file(File.join(File.dirname(__FILE__), "..", "config", "database.yml"))
ActiveRecord::Base.establish_connection(db_config["test"])
ActiveRecord::Base.logger = Logger.new(File.open(File.join(File.dirname(__FILE__), "..", "log", "tests.log"), 'a'))

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.

Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  # config.order = 'random'
  config.infer_spec_type_from_file_location!
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end