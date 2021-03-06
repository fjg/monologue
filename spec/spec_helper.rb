# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/config/environment', __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-webkit'

require 'factory_girl_rails'
require 'shoulda'

require 'coveralls'
Coveralls.wear!

ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), '../')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/support/**/*.rb')].each { |f| require f }
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/factories/**/*.rb')].each do |f|
  require f
end

Capybara.default_driver = :rack_test
Capybara.always_include_port = true
Capybara.javascript_driver = :webkit

Capybara::Webkit.configure do |config|
  # Enable debug mode. Prints a log of everything the driver is doing.
  config.debug = false

  # see dummy app (environments/test.rb)
  config.allow_url('*.127.0.0.1.xip.io') # cf. monologue/site factories
end

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
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
  # config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  [:controller, :view, :request, :feature].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.before(:suite) do
  end

  config.before(:each) do
    Mongoid::Clients.default.collections.each do |collection|
      collection.drop unless collection.name =~ /^system\./
    end
    ActionController::Base.perform_caching = false
  end

  config.after(:each) do
  end
end
