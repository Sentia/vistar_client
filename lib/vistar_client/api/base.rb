# frozen_string_literal: true

module VistarClient
  module API
    # Base module for all API endpoint modules.
    #
    # Provides shared functionality for making authenticated API requests.
    #
    # @api private
    module Base
      private

      # Get the connection object from the client.
      #
      # @return [VistarClient::Connection] the HTTP connection
      def connection
        @connection
      end

      # Get the network_id from the client.
      #
      # @return [String] the network ID
      def network_id
        @network_id
      end
    end
  end
end
