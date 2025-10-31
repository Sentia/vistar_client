# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require_relative 'middleware/error_handler'

module VistarClient
  # Manages HTTP connections to the Vistar Media API.
  #
  # This class encapsulates Faraday connection configuration including:
  # - JSON request/response handling
  # - Automatic retry logic for transient failures
  # - Custom error handling middleware
  # - Request/response logging (when VISTAR_DEBUG is set)
  # - Timeout configuration
  # - Authentication headers
  #
  # @api private
  class Connection
    # @return [String] the API key for authentication
    attr_reader :api_key

    # @return [String] the base URL for the API
    attr_reader :api_base_url

    # @return [Integer] the timeout for HTTP requests in seconds
    attr_reader :timeout

    # Initialize a new HTTP connection manager.
    #
    # @param api_key [String] the API key for authentication
    # @param api_base_url [String] the base URL for the API
    # @param timeout [Integer] the timeout for HTTP requests in seconds
    def initialize(api_key:, api_base_url:, timeout:)
      @api_key = api_key
      @api_base_url = api_base_url
      @timeout = timeout
    end

    # Get or create a Faraday connection instance.
    #
    # The connection is cached and reused for subsequent requests.
    #
    # @return [Faraday::Connection] a configured Faraday connection
    def get
      @get ||= build_connection
    end
    alias to_faraday get

    # Make a POST request.
    #
    # @param path [String] the API endpoint path
    # @param payload [Hash] the request body
    # @return [Faraday::Response] the HTTP response
    def post(path, payload)
      get.post(path, payload)
    end

    # Make a GET request.
    #
    # @param path [String] the API endpoint path
    # @param params [Hash] the query parameters
    # @return [Faraday::Response] the HTTP response
    def get_request(path, params = {})
      get.get(path, params)
    end

    # Delegate method_missing to the underlying Faraday connection
    # to maintain backward compatibility with tests.
    #
    # @param method [Symbol] the method name
    # @param args [Array] the method arguments
    # @param block [Proc] the block to pass to the method
    # @return [Object] the result of the delegated method call
    def method_missing(method, ...)
      if get.respond_to?(method)
        get.public_send(method, ...)
      else
        super
      end
    end

    # Check if the connection responds to a method.
    #
    # @param method [Symbol] the method name
    # @param include_private [Boolean] whether to include private methods
    # @return [Boolean] whether the connection responds to the method
    def respond_to_missing?(method, include_private = false)
      get.respond_to?(method, include_private) || super
    end

    private

    # Build and configure a new Faraday connection.
    #
    # @return [Faraday::Connection] a configured Faraday connection
    def build_connection
      Faraday.new(url: api_base_url) do |faraday|
        configure_headers(faraday)
        configure_request_middleware(faraday)
        configure_response_middleware(faraday)
        configure_adapter(faraday)
        configure_timeouts(faraday)
      end
    end

    # Configure default HTTP headers.
    #
    # @param faraday [Faraday::Connection] the connection to configure
    # @return [void]
    def configure_headers(faraday)
      faraday.headers['Authorization'] = "Bearer #{api_key}"
      faraday.headers['Accept'] = 'application/json'
      faraday.headers['Content-Type'] = 'application/json'
    end

    # Configure request middleware stack.
    #
    # @param faraday [Faraday::Connection] the connection to configure
    # @return [void]
    def configure_request_middleware(faraday)
      faraday.request :json
      faraday.request :retry,
                      max: 3,
                      interval: 0.5,
                      interval_randomness: 0.5,
                      backoff_factor: 2,
                      retry_statuses: [429, 500, 502, 503, 504],
                      methods: %i[get post put patch delete]
    end

    # Configure response middleware stack.
    # Order matters - middleware runs in reverse order for responses.
    #
    # @param faraday [Faraday::Connection] the connection to configure
    # @return [void]
    def configure_response_middleware(faraday)
      # Error handler runs after JSON parsing (sees parsed body)
      faraday.use VistarClient::Middleware::ErrorHandler
      faraday.response :json, content_type: /\bjson$/

      # Optional logging
      faraday.response :logger, nil, { headers: true, bodies: true } if ENV['VISTAR_DEBUG']
    end

    # Configure the HTTP adapter.
    #
    # @param faraday [Faraday::Connection] the connection to configure
    # @return [void]
    def configure_adapter(faraday)
      faraday.adapter Faraday.default_adapter
    end

    # Configure timeout settings.
    #
    # @param faraday [Faraday::Connection] the connection to configure
    # @return [void]
    def configure_timeouts(faraday)
      faraday.options.timeout = timeout
      faraday.options.open_timeout = timeout
    end
  end
end
