# VistarClient

A Ruby client library for the Vistar Media API. Provides a clean, type-safe interface for ad serving, proof-of-play submission, and campaign management.

## Installation

Add to your application's Gemfile:

```ruby
gem 'vistar_client'
```

Then execute:

```bash
bundle install
```

## Usage

```ruby
require 'vistar_client'

# Initialize the client
client = VistarClient::Client.new(
  network_id: 'your_network_id',
  api_key: 'your_api_key'
)

# Request an ad
ad = client.request_ad(
  venue_id: 'venue_123',
  display_area: [{ id: 'screen_1', width: 1920, height: 1080 }]
)

# Submit proof of play
client.submit_proof_of_play(ad['proof_of_play_url'])
```

## Features

- Faraday-based HTTP client with configurable middleware
- Custom error classes for precise exception handling
- Automatic request/response JSON encoding and parsing
- Built-in retry logic for transient failures
- Comprehensive test coverage with RSpec
- Full YARD documentation

## Configuration

```ruby
client = VistarClient::Client.new(
  network_id: 'your_network_id',
  api_key: 'your_api_key',
  timeout: 60,                                          # Optional, default: 60
  api_base_url: 'https://trafficking.vistarmedia.com/' # Optional
)
```

## Error Handling

```ruby
begin
  ad = client.request_ad(params)
rescue VistarClient::AuthenticationError => e
  # Handle invalid credentials
rescue VistarClient::APIError => e
  # Handle API errors (4xx, 5xx)
rescue VistarClient::ConnectionError => e
  # Handle network failures
end
```

## Development and Testing

After checking out the repo, run `bin/setup` to install dependencies. Then run:

```bash
rake spec         # Run tests
rubocop           # Check code style
yard doc          # Generate documentation
```

To install locally: `bundle exec rake install`

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
