# VistarClient

![CI](https://github.com/Sentia/vistar_client/workflows/CI/badge.svg)
[![Gem Version](https://badge.fury.io/rb/vistar_client.svg)](https://badge.fury.io/rb/vistar_client)
[![codecov](https://codecov.io/gh/Sentia/vistar_client/branch/main/graph/badge.svg)](https://codecov.io/gh/Sentia/vistar_client)

A Ruby client library for the Vistar Media API. Provides a clean, modular interface for programmatic ad serving and proof-of-play submission.

## Installation

Add to your application's Gemfile:

```ruby
gem 'vistar_client'
```

Then execute:

```bash
bundle install
```

## Quick Start

```ruby
require 'vistar_client'

# Initialize the client
client = VistarClient::Client.new(
  api_key: ENV['VISTAR_API_KEY'],
  network_id: ENV['VISTAR_NETWORK_ID']
)

# Request an ad
ad = client.request_ad(
  device_id: 'device-123',
  display_area: { width: 1920, height: 1080 },
  latitude: 37.7749,
  longitude: -122.4194,
  duration_ms: 15_000
)

# Submit proof of play after displaying the ad
client.submit_proof_of_play(
  advertisement_id: ad['advertisement']['id'],
  display_time: Time.now,
  duration_ms: 15_000,
  device_id: 'device-123'
)
```

## Architecture

The gem uses a modular architecture for clean separation of concerns and easy extensibility:

```
VistarClient
├── Client              # Main entry point
├── Connection          # HTTP client wrapper
├── API
│   ├── Base           # Shared API module functionality
│   └── AdServing      # Ad serving endpoints (request_ad, submit_proof_of_play)
├── Middleware
│   └── ErrorHandler   # Custom error handling
└── Error Classes      # AuthenticationError, APIError, ConnectionError
```

### Connection Layer

The `VistarClient::Connection` class manages HTTP communication:
- Wraps Faraday with method delegation
- Configures JSON request/response handling
- Implements automatic retry logic (3 retries with exponential backoff)
- Handles authentication headers
- Provides optional debug logging (set `VISTAR_DEBUG=1`)

### API Modules

API endpoints are organized into modules by feature domain:
- `API::AdServing`: Request ads and submit proof of play
- Future: `API::CreativeCaching`, `API::UnifiedServing` (Sprint 2+)

## Features

- **Modular Architecture**: Clean separation between HTTP layer and business logic
- **Comprehensive Error Handling**: Custom exceptions for authentication, API, and connection failures
- **Automatic Retries**: Built-in retry logic for transient failures (429, 5xx errors)
- **Type Safety**: Parameter validation with descriptive error messages
- **Debug Logging**: Optional request/response logging via `VISTAR_DEBUG` environment variable
- **Full Test Coverage**: 98.73% code coverage with 118 test examples
- **Complete Documentation**: 100% YARD documentation coverage

## API Methods

### Request Ad

Request a programmatic ad from the Vistar Media API.

```ruby
response = client.request_ad(
  device_id: 'device-123',              # required: unique device identifier
  display_area: { width: 1920, height: 1080 },  # required: display dimensions in pixels
  latitude: 37.7749,                    # required: device latitude (-90 to 90)
  longitude: -122.4194,                 # required: device longitude (-180 to 180)
  
  # Optional parameters:
  duration_ms: 15_000,                  # ad duration in milliseconds
  device_type: 'billboard',             # device type (e.g., 'billboard', 'kiosk')
  allowed_media_types: ['image/jpeg', 'video/mp4']  # supported media types
)
```

**Returns**: Hash containing ad data from the Vistar API

**Raises**:
- `ArgumentError`: Invalid or missing required parameters
- `AuthenticationError`: Invalid API key (401)
- `APIError`: API error response (4xx/5xx)
- `ConnectionError`: Network failure

### Submit Proof of Play

Confirm that an ad was displayed.

```ruby
response = client.submit_proof_of_play(
  advertisement_id: 'ad-789',           # required: ID from ad response
  display_time: Time.now,               # required: when ad was displayed (Time or ISO8601 string)
  duration_ms: 15_000,                  # required: how long ad was displayed (positive integer)
  
  # Optional parameters:
  device_id: 'device-123',              # device that displayed the ad
  venue_metadata: { venue_id: 'venue-456' }  # additional venue information
)
```

**Returns**: Hash containing proof of play confirmation

**Raises**: Same as `request_ad`

## Configuration

```ruby
client = VistarClient::Client.new(
  api_key: 'your-api-key',                              # required
  network_id: 'your-network-id',                        # required
  api_base_url: 'https://api.vistarmedia.com',         # optional (default shown)
  timeout: 10                                            # optional, in seconds (default: 10)
)
```

### Debug Logging

Enable detailed request/response logging:

```bash
VISTAR_DEBUG=1 bundle exec ruby your_script.rb
```

## Error Handling

All errors inherit from `VistarClient::Error`, allowing you to rescue all gem errors with a single clause:

```ruby
begin
  ad = client.request_ad(params)
rescue VistarClient::AuthenticationError => e
  # Handle invalid API credentials (401)
  puts "Authentication failed: #{e.message}"
  
rescue VistarClient::APIError => e
  # Handle API errors (4xx/5xx)
  puts "API error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Response body: #{e.response_body}"
  
rescue VistarClient::ConnectionError => e
  # Handle network failures (timeouts, DNS, etc.)
  puts "Network error: #{e.message}"
  
rescue VistarClient::Error => e
  # Catch-all for any gem error
  puts "Vistar client error: #{e.message}"
end
```

### Error Classes

- `VistarClient::Error`: Base class for all gem errors
- `VistarClient::AuthenticationError`: Invalid or missing credentials (HTTP 401)
- `VistarClient::APIError`: API returned an error response (HTTP 4xx/5xx)
  - Includes `status_code` and `response_body` attributes
- `VistarClient::ConnectionError`: Network failure (timeout, connection refused, DNS, etc.)

## Extending the Client

The modular architecture makes it easy to add new API endpoints. Here's how to add a new API module:

### Step 1: Create a New API Module

```ruby
# lib/vistar_client/api/creative_caching.rb
module VistarClient
  module API
    module CreativeCaching
      include Base
      
      def get_asset(asset_id:, **options)
        # Validate parameters
        raise ArgumentError, 'asset_id is required' if asset_id.nil?
        
        # Build payload
        payload = { asset_id: asset_id, network_id: network_id }.merge(options)
        
        # Make API request
        response = connection.post('/api/v1/get_asset', payload)
        response.body
      end
    end
  end
end
```

### Step 2: Include in Client

```ruby
# lib/vistar_client/client.rb
require_relative 'api/creative_caching'

module VistarClient
  class Client
    include API::AdServing
    include API::CreativeCaching  # Add your new module
    
    # ... rest of implementation
  end
end
```

### Step 3: Write Tests

```ruby
# spec/vistar_client/api/creative_caching_spec.rb
RSpec.describe VistarClient::API::CreativeCaching do
  # Test your new methods
end
```

### Benefits of This Architecture

- **Separation of Concerns**: Each API module handles one feature domain
- **Easy Testing**: Modules can be tested independently
- **No Bloat**: Client class stays small, functionality is composed
- **Maintainability**: Changes to one API group don't affect others
- **Discoverability**: Clear file structure shows available features

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Environment Setup

1. Copy `.env.example` to `.env`
2. Add your Vistar API credentials
3. Use `staging_client` helper in console for testing

### Running Tests

```bash
bundle exec rspec         # Run all tests
bundle exec rspec --tag focus  # Run focused tests
bundle exec rspec --profile    # Show slowest tests
```

### Code Quality

```bash
bundle exec rubocop       # Check code style
bundle exec rubocop -A    # Auto-correct offenses
```

### Documentation

```bash
bundle exec yard doc      # Generate documentation
bundle exec yard server   # View docs at http://localhost:8808
```

### Interactive Console

```bash
bin/console               # Start Pry console with gem loaded
```

The console provides helper methods:
- `staging_client` - Creates a client configured for Vistar staging environment

### Installing Locally

```bash
bundle exec rake install  # Install gem locally
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
