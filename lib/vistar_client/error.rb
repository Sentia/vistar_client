# frozen_string_literal: true

module VistarClient
  # Base error class for all VistarClient gem errors.
  #
  # All custom errors in this gem inherit from this class, allowing you to rescue
  # all gem-specific errors with a single rescue clause.
  #
  # @example Rescue all VistarClient errors
  #   begin
  #     client.request_ad(params)
  #   rescue VistarClient::Error => e
  #     puts "VistarClient error: #{e.message}"
  #   end
  #
  class Error < StandardError; end

  # Raised when API authentication fails (HTTP 401).
  #
  # This typically indicates invalid or missing API credentials.
  #
  # @example Handle authentication errors
  #   begin
  #     client.request_ad(params)
  #   rescue VistarClient::AuthenticationError => e
  #     puts "Authentication failed: #{e.message}"
  #     puts "Please check your API key and network ID"
  #   end
  #
  class AuthenticationError < Error; end

  # Raised when the API returns an error response (HTTP 4xx/5xx).
  #
  # This error includes the HTTP status code and response body for debugging.
  #
  # @example Handle API errors
  #   begin
  #     client.request_ad(params)
  #   rescue VistarClient::APIError => e
  #     puts "API error: #{e.message}"
  #     puts "Status code: #{e.status_code}"
  #     puts "Response body: #{e.response_body}"
  #   end
  #
  class APIError < Error
    # @return [Integer, nil] HTTP status code from the error response
    attr_reader :status_code

    # @return [Hash, String, nil] Response body from the error response
    attr_reader :response_body

    # Initialize an APIError with optional HTTP details.
    #
    # @param message [String] Error message
    # @param status_code [Integer, nil] HTTP status code
    # @param response_body [Hash, String, nil] Response body
    #
    def initialize(message, status_code: nil, response_body: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end

  # Raised when a network connection failure occurs.
  #
  # This includes timeouts, connection refused, DNS failures, etc.
  #
  # @example Handle connection errors
  #   begin
  #     client.request_ad(params)
  #   rescue VistarClient::ConnectionError => e
  #     puts "Network error: #{e.message}"
  #     puts "Please check your internet connection"
  #   end
  #
  class ConnectionError < Error; end
end
