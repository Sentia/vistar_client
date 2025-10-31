# frozen_string_literal: true

require 'faraday'

module VistarClient
  # Faraday middleware components for the Vistar Media API client.
  #
  # This namespace contains custom Faraday middleware for:
  # - Error handling and exception mapping
  # - Request/response processing
  #
  # @see VistarClient::Middleware::ErrorHandler
  module Middleware
    # Faraday response middleware that intercepts HTTP responses and raises
    # appropriate VistarClient exceptions based on status codes.
    #
    # This middleware handles:
    # - 401 Unauthorized -> AuthenticationError
    # - 4xx/5xx errors -> APIError (with status code and response body)
    # - Network/connection failures -> ConnectionError
    #
    # @example
    #   Faraday.new do |f|
    #     f.response :json
    #     f.use VistarClient::Middleware::ErrorHandler
    #     f.adapter Faraday.default_adapter
    #   end
    class ErrorHandler < Faraday::Middleware
      # HTTP status codes that should raise exceptions
      CLIENT_ERROR_RANGE = (400..499)

      # HTTP status codes for server errors
      SERVER_ERROR_RANGE = (500..599)

      # Process the request and handle any errors
      #
      # @param request_env [Faraday::Env] the request environment
      # @return [Faraday::Response] the response
      # @raise [AuthenticationError] for 401 status
      # @raise [APIError] for other 4xx/5xx status codes
      # @raise [ConnectionError] for network failures
      def call(request_env)
        response = @app.call(request_env)
        check_for_errors(response)
        response
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        raise ConnectionError, "Connection failed: #{e.message}"
      rescue Faraday::Error => e
        raise ConnectionError, "Network error: #{e.message}"
      end

      private

      # Check response for errors and raise appropriate exceptions
      #
      # @param response [Faraday::Response] the HTTP response
      # @return [void]
      def check_for_errors(response)
        case response.status
        when 401
          handle_unauthorized(response)
        when CLIENT_ERROR_RANGE, SERVER_ERROR_RANGE
          handle_api_error(response)
        end
      end

      # Handle 401 Unauthorized responses
      #
      # @param response [Faraday::Response] the HTTP response
      # @raise [AuthenticationError]
      def handle_unauthorized(response)
        message = extract_error_message(response.body) || 'Authentication failed'
        raise AuthenticationError, message
      end

      # Handle other 4xx/5xx API errors
      #
      # @param response [Faraday::Response] the HTTP response
      # @raise [APIError]
      def handle_api_error(response)
        message = extract_error_message(response.body) || "API request failed with status #{response.status}"
        raise APIError.new(message, status_code: response.status, response_body: response.body)
      end

      # Extract error message from response body
      #
      # @param body [Hash, String, nil] the response body
      # @return [String, nil] the error message if found
      def extract_error_message(body)
        return nil unless body.is_a?(Hash)

        body['error'] || body['message'] || body['error_description']
      end
    end
  end
end
