# frozen_string_literal: true

require 'faraday'

module VistarClient
  module Middleware
    # Faraday middleware that intercepts HTTP responses and raises
    # appropriate VistarClient exceptions based on status codes.
    #
    # This middleware handles:
    # - 401 Unauthorized -> AuthenticationError
    # - 4xx/5xx errors -> APIError (with status code and response body)
    # - Network/connection failures -> ConnectionError
    #
    # @example
    #   Faraday.new do |f|
    #     f.use VistarClient::Middleware::ErrorHandler
    #     f.adapter Faraday.default_adapter
    #   end
    class ErrorHandler < Faraday::Middleware
      # HTTP status codes that should raise exceptions
      CLIENT_ERROR_RANGE = (400..499)
      SERVER_ERROR_RANGE = (500..599)

      # Initialize the middleware
      #
      # @param app [#call] the next middleware in the stack
      # @param options [Hash] optional configuration (reserved for future use)
      def initialize(app, options = {})
        super(app)
        @options = options
      end

      # Process the request and handle any errors
      #
      # @param env [Faraday::Env] the request environment
      # @return [Faraday::Response] the response
      # @raise [AuthenticationError] for 401 status
      # @raise [APIError] for other 4xx/5xx status codes
      # @raise [ConnectionError] for network failures
      def call(env)
        @app.call(env)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        raise ConnectionError, "Connection failed: #{e.message}"
      rescue Faraday::Error => e
        raise ConnectionError, "Network error: #{e.message}"
      end

      # Handle the response after it's received
      #
      # @param env [Faraday::Env] the request environment
      # @return [void]
      def on_complete(env)
        case env[:status]
        when 401
          handle_unauthorized(env)
        when CLIENT_ERROR_RANGE, SERVER_ERROR_RANGE
          handle_api_error(env)
        end
      end

      private

      # Handle 401 Unauthorized responses
      #
      # @param env [Faraday::Env] the request environment
      # @raise [AuthenticationError]
      def handle_unauthorized(env)
        message = extract_error_message(env) || 'Authentication failed'
        raise AuthenticationError, message
      end

      # Handle other 4xx/5xx API errors
      #
      # @param env [Faraday::Env] the request environment
      # @raise [APIError]
      def handle_api_error(env)
        message = extract_error_message(env) || "API request failed with status #{env[:status]}"
        raise APIError.new(message, status_code: env[:status], response_body: env[:body])
      end

      # Extract error message from response body
      #
      # @param env [Faraday::Env] the request environment
      # @return [String, nil] the error message if found
      def extract_error_message(env)
        return nil unless env[:body].is_a?(Hash)

        env[:body]['error'] || env[:body]['message'] || env[:body]['error_description']
      end
    end
  end
end
