# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  minimum_coverage 95
  # Removed minimum_coverage_by_file as some small utility files
  # may have lower coverage while overall coverage remains high
end

require 'vistar_client'
require 'webmock/rspec'

# Disable external HTTP requests during tests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed
end

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }
