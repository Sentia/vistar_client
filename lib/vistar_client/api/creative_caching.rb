# frozen_string_literal: true

require_relative 'base'

module VistarClient
  module API
    # Creative Caching API methods for pre-fetching and caching creative assets.
    #
    # This module implements the Vistar Media Creative Caching API which allows
    # media owners to request and cache creatives in advance. This is beneficial
    # for poor internet connectivity scenarios and bandwidth optimization.
    #
    # Returns all creatives that qualify to run on a venue over the next 30 hours.
    #
    # @see https://help.vistarmedia.com/hc/en-us/articles/224987348-Creative-caching-endpoint
    module CreativeCaching
      include Base

      # Request creative assets for caching in advance.
      #
      # Returns all creatives that qualify to run on the specified venue over the
      # next 30 hours based on campaign targeting. Recommended to call once daily
      # combined with downloading assets on first sight for dynamic creatives.
      #
      # @param device_id [String] unique identifier for the device (required)
      # @param venue_id [String] venue identifier making the request (required)
      # @param display_time [Integer] time to match relevant assets in UTC epoch seconds (required)
      # @param display_area [Hash] display configuration (required, keys: :id, :width, :height, :supported_media)
      # @param options [Hash] optional parameters
      # @option options [Array<Hash>] :device_attribute custom targeting attributes
      # @option options [Float] :latitude degrees north (optional)
      # @option options [Float] :longitude degrees east (optional)
      #
      # @return [Hash] response containing array of assets with metadata
      #
      # @raise [ArgumentError] if required parameters are missing or invalid
      # @raise [AuthenticationError] if API key is invalid (401)
      # @raise [APIError] for other API errors (4xx/5xx)
      # @raise [ConnectionError] for network failures
      #
      # @example Basic usage
      #   assets = client.get_asset(
      #     device_id: 'device-123',
      #     venue_id: 'venue-456',
      #     display_time: Time.now.to_i,
      #     display_area: {
      #       id: 'display-0',
      #       width: 1920,
      #       height: 1080,
      #       supported_media: ['image/jpeg', 'video/mp4'],
      #       allow_audio: false
      #     }
      #   )
      #
      # @example With optional parameters
      #   assets = client.get_asset(
      #     device_id: 'device-123',
      #     venue_id: 'venue-456',
      #     display_time: Time.now.to_i + 3600,
      #     display_area: {
      #       id: 'display-0',
      #       width: 1920,
      #       height: 1080,
      #       supported_media: ['image/jpeg', 'video/mp4']
      #     },
      #     device_attribute: [
      #       { name: 'location', value: 'lobby' }
      #     ],
      #     latitude: 37.7749,
      #     longitude: -122.4194
      #   )
      def get_asset(device_id:, venue_id:, display_time:, display_area:, **options)
        validate_get_asset_params!(device_id, venue_id, display_time, display_area)

        payload = build_get_asset_payload(device_id, venue_id, display_time, display_area, options)

        response = connection.post('/api/v1/get_asset/json', payload)
        response.body
      end

      private

      # Validate get_asset parameters.
      #
      # @param device_id [String] the device ID
      # @param venue_id [String] the venue ID
      # @param display_time [Integer] the display time in epoch seconds
      # @param display_area [Hash] the display area configuration
      #
      # @raise [ArgumentError] if any parameter is invalid
      #
      # @return [void]
      def validate_get_asset_params!(device_id, venue_id, display_time, display_area)
        raise ArgumentError, 'device_id is required' if device_id.nil? || device_id.to_s.empty?
        raise ArgumentError, 'venue_id is required' if venue_id.nil? || venue_id.to_s.empty?
        raise ArgumentError, 'display_time is required' if display_time.nil?
        raise ArgumentError, 'display_time must be an integer' unless display_time.is_a?(Integer)
        raise ArgumentError, 'display_area is required and must be a Hash' unless display_area.is_a?(Hash)

        validate_display_area!(display_area)
      end

      # Validate display_area configuration.
      #
      # @param display_area [Hash] the display area configuration
      #
      # @raise [ArgumentError] if display_area is invalid
      #
      # @return [void]
      def validate_display_area!(display_area)
        raise ArgumentError, 'display_area must include :id' unless display_area[:id]
        raise ArgumentError, 'display_area must include :width' unless display_area[:width]
        raise ArgumentError, 'display_area must include :height' unless display_area[:height]

        return if display_area[:supported_media].is_a?(Array) && !display_area[:supported_media].empty?

        raise ArgumentError, 'display_area must include :supported_media array'
      end

      # Build payload for get_asset request.
      #
      # @param device_id [String] the device ID
      # @param venue_id [String] the venue ID
      # @param display_time [Integer] the display time
      # @param display_area [Hash] the display area configuration
      # @param options [Hash] additional optional parameters
      #
      # @return [Hash] the request payload
      def build_get_asset_payload(device_id, venue_id, display_time, display_area, options)
        {
          network_id: network_id,
          api_key: api_key,
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: [display_area],
          direct_connection: false
        }.merge(options.slice(:device_attribute, :latitude, :longitude))
      end

      # Get the API key from the client.
      #
      # @return [String] the API key
      def api_key
        @api_key
      end
    end
  end
end
