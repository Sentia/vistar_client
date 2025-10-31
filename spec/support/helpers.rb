# frozen_string_literal: true

module VistarClient
  module TestHelpers
    def fixture_path(filename)
      File.join(File.dirname(__FILE__), '../fixtures', filename)
    end

    def load_fixture(filename)
      File.read(fixture_path(filename))
    end

    def json_fixture(filename)
      JSON.parse(load_fixture("#{filename}.json"))
    end
  end
end

RSpec.configure do |config|
  config.include VistarClient::TestHelpers
end
