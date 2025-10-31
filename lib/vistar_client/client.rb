# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'
require_relative 'middleware/error_handler'

module VistarClient
  # The main client class for interacting with the Vistar Media API.
  #
  # @example Initialize a client
  #   client = VistarClient::Client.new(
  #     api_key: 'your-api-key',
  #     network_id: 'your-network-id'
  #   )
  #
  # @example With custom configuration
  #   client = VistarClient::Client.new(
  #     api_key: 'your-api-key',
  #     network_id: 'your-network-id',
  #     api_base_url: 'https://api.vistarmedia.com',
  #     timeout: 30
  #   )
  class Client
    # Default API base URL for Vistar Media
    DEFAULT_API_BASE_URL = 'https://api.vistarmedia.com'

    # Default timeout for HTTP requests in seconds
    DEFAULT_TIMEOUT = 10

    # @return [String] the API key for authentication
    attr_reader :api_key

    # @return [String] the network ID
    attr_reader :network_id

    # @return [String] the base URL for the API
    attr_reader :api_base_url

    # @return [Integer] the timeout for HTTP requests in seconds
    attr_reader :timeout

    # Initialize a new Vistar Media API client.
    #
    # @param api_key [String] the API key for authentication (required)
    # @param network_id [String] the network ID (required)
    # @param api_base_url [String] the base URL for the API (optional, defaults to production)
    # @param timeout [Integer] the timeout for HTTP requests in seconds (optional, defaults to 10)
    #
    # @raise [ArgumentError] if api_key or network_id is missing or empty
    #
    # @example
    #   client = VistarClient::Client.new(
    #     api_key: 'your-api-key',
    #     network_id: 'your-network-id'
    #   )
    def initialize(api_key:, network_id:, api_base_url: DEFAULT_API_BASE_URL, timeout: DEFAULT_TIMEOUT)
      validate_credentials!(api_key, network_id)

      @api_key = api_key
      @network_id = network_id
      @api_base_url = api_base_url
      @timeout = timeout
    end

    private

    # Validate that required credentials are present and not empty.
    #
    # @param api_key [String] the API key to validate
    # @param network_id [String] the network ID to validate
    #
    # @raise [ArgumentError] if either parameter is nil or empty
    #
    # @return [void]
    def validate_credentials!(api_key, network_id)
      raise ArgumentError, 'api_key is required and cannot be empty' if api_key.nil? || api_key.empty?
      raise ArgumentError, 'network_id is required and cannot be empty' if network_id.nil? || network_id.empty?
    end

    # Create and configure a Faraday connection instance.
    #
    # The connection includes:
    # - JSON request/response handling
    # - Automatic retry logic for transient failures
    # - Custom error handling (maps HTTP errors to gem exceptions)
    # - Request/response logging (when VISTAR_DEBUG is set)
    # - Timeout configuration
    # - Authorization header with Bearer token
    #
    # @return [Faraday::Connection] a configured Faraday connection
    def connection
      @connection ||= Faraday.new(url: api_base_url) do |faraday|
        # Set default headers
        faraday.headers['Authorization'] = "Bearer #{api_key}"
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['Content-Type'] = 'application/json'

        # Request middleware
        faraday.request :json
        faraday.request :retry, {
          max: 3,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504],
          methods: %i[get post put patch delete]
        }

        # Response middleware
        faraday.response :json, content_type: /\bjson$/

        # Custom error handling middleware
        faraday.use VistarClient::Middleware::ErrorHandler

        # Logging middleware (only when debugging)
        faraday.response :logger, nil, { headers: true, bodies: true } if ENV['VISTAR_DEBUG']

        # Adapter
        faraday.adapter Faraday.default_adapter

        # Configure timeout
        faraday.options.timeout = timeout
        faraday.options.open_timeout = timeout
      end
    end
  end
end
