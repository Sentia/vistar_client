# frozen_string_literal: true

require_relative 'connection'
require_relative 'api/ad_serving'
require_relative 'api/creative_caching'

module VistarClient
  # The main client class for interacting with the Vistar Media API.
  #
  # This class serves as the primary entry point for all API operations.
  # It delegates to specialized API modules for different endpoint groups.
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
    include API::AdServing
    include API::CreativeCaching

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

      @connection = Connection.new(
        api_key: api_key,
        api_base_url: api_base_url,
        timeout: timeout
      )
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

    # Get the HTTP connection instance.
    #
    # @return [VistarClient::Connection] the HTTP connection
    attr_reader :connection
  end
end
