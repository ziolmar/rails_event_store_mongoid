if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'pry'
require 'database_cleaner'
require 'mongoid'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store_mongoid'

ENV['MONGOID_ENV'] ||= 'test'
Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__))

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner[:mongoid].start
  end

  config.after(:each) do
    DatabaseCleaner[:mongoid].clean
  end
end
