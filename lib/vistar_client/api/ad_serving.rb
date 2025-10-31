# frozen_string_literal: true

require_relative 'base'

module VistarClient
  module API
    # Ad Serving API methods for requesting ads and submitting proof of play.
    #
    # This module implements the core Vistar Media Ad Serving API:
    # - GetAd endpoint: Request programmatic ads
    # - Proof of Play endpoint: Confirm ad display
    #
    # @see https://help.vistarmedia.com/hc/en-us/articles/225058628-Ad-Serving-API
    module AdServing
      include Base

      # Request an ad from the Vistar Media API.
      #
      # @param device_id [String] unique identifier for the device (required)
      # @param display_area [Hash] display dimensions (required, keys: :width, :height in pixels)
      # @param latitude [Float] device latitude (required)
      # @param longitude [Float] device longitude (required)
      # @param options [Hash] optional parameters
      # @option options [Integer] :duration_ms ad duration in milliseconds
      # @option options [String] :device_type type of device (e.g., 'billboard', 'kiosk')
      # @option options [Array<String>] :allowed_media_types supported media types (e.g., ['image/jpeg', 'video/mp4'])
      #
      # @return [Hash] ad response data from the API
      #
      # @raise [ArgumentError] if required parameters are missing or invalid
      # @raise [AuthenticationError] if API key is invalid (401)
      # @raise [APIError] for other API errors (4xx/5xx)
      # @raise [ConnectionError] for network failures
      #
      # @example
      #   response = client.request_ad(
      #     device_id: 'device-123',
      #     display_area: { width: 1920, height: 1080 },
      #     latitude: 37.7749,
      #     longitude: -122.4194,
      #     duration_ms: 15_000
      #   )
      def request_ad(device_id:, display_area:, latitude:, longitude:, **options)
        validate_request_ad_params!(device_id, display_area, latitude, longitude)

        payload = build_ad_request_payload(device_id, display_area, latitude, longitude, options)

        response = connection.post('/api/v1/get_ad', payload)
        response.body
      end

      # Submit proof of play for a displayed ad.
      #
      # @param advertisement_id [String] ID of the advertisement that was displayed (required)
      # @param display_time [Time, String] when the ad was displayed (required)
      # @param duration_ms [Integer] how long the ad was displayed in milliseconds (required)
      # @param options [Hash] optional parameters
      # @option options [String] :device_id device that displayed the ad
      # @option options [Hash] :venue_metadata additional venue information
      #
      # @return [Hash] proof of play confirmation from the API
      #
      # @raise [ArgumentError] if required parameters are missing or invalid
      # @raise [AuthenticationError] if API key is invalid (401)
      # @raise [APIError] for other API errors (4xx/5xx)
      # @raise [ConnectionError] for network failures
      #
      # @example
      #   response = client.submit_proof_of_play(
      #     advertisement_id: 'ad-789',
      #     display_time: Time.now,
      #     duration_ms: 15_000,
      #     device_id: 'device-123'
      #   )
      def submit_proof_of_play(advertisement_id:, display_time:, duration_ms:, **options)
        validate_proof_of_play_params!(advertisement_id, display_time, duration_ms)

        payload = build_proof_of_play_payload(advertisement_id, display_time, duration_ms, options)

        response = connection.post('/api/v1/proof_of_play', payload)
        response.body
      end

      private

      # Validate request_ad parameters.
      #
      # @param device_id [String] the device ID
      # @param display_area [Hash] the display area dimensions
      # @param latitude [Float] the latitude coordinate
      # @param longitude [Float] the longitude coordinate
      #
      # @raise [ArgumentError] if any parameter is invalid
      #
      # @return [void]
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def validate_request_ad_params!(device_id, display_area, latitude, longitude)
        raise ArgumentError, 'device_id is required' if device_id.nil? || device_id.to_s.empty?
        raise ArgumentError, 'display_area is required and must be a Hash' unless display_area.is_a?(Hash)

        unless display_area[:width] && display_area[:height]
          raise ArgumentError,
                'display_area must include :width and :height'
        end

        raise ArgumentError, 'latitude is required' if latitude.nil?
        raise ArgumentError, 'longitude is required' if longitude.nil?
        raise ArgumentError, 'latitude must be between -90 and 90' unless latitude.between?(-90, 90)
        raise ArgumentError, 'longitude must be between -180 and 180' unless longitude.between?(-180, 180)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Validate proof_of_play parameters.
      #
      # @param advertisement_id [String] the advertisement ID
      # @param display_time [Time, String] when the ad was displayed
      # @param duration_ms [Integer] how long the ad was displayed
      #
      # @raise [ArgumentError] if any parameter is invalid
      #
      # @return [void]
      def validate_proof_of_play_params!(advertisement_id, display_time, duration_ms)
        raise ArgumentError, 'advertisement_id is required' if advertisement_id.nil? || advertisement_id.to_s.empty?
        raise ArgumentError, 'display_time is required' if display_time.nil?

        return if duration_ms.is_a?(Integer) && duration_ms.positive?

        raise ArgumentError,
              'duration_ms is required and must be a positive integer'
      end

      # Build payload for ad request.
      #
      # @param device_id [String] the device ID
      # @param display_area [Hash] the display area dimensions
      # @param latitude [Float] the latitude coordinate
      # @param longitude [Float] the longitude coordinate
      # @param options [Hash] additional optional parameters
      #
      # @return [Hash] the request payload
      def build_ad_request_payload(device_id, display_area, latitude, longitude, options)
        {
          device_id: device_id,
          network_id: network_id,
          display_area: display_area,
          latitude: latitude,
          longitude: longitude
        }.merge(options.slice(:duration_ms, :device_type, :allowed_media_types))
      end

      # Build payload for proof of play submission.
      #
      # @param advertisement_id [String] the advertisement ID
      # @param display_time [Time, String] when the ad was displayed
      # @param duration_ms [Integer] how long the ad was displayed
      # @param options [Hash] additional optional parameters
      #
      # @return [Hash] the request payload
      def build_proof_of_play_payload(advertisement_id, display_time, duration_ms, options)
        timestamp = display_time.is_a?(Time) ? display_time.iso8601 : display_time.to_s

        {
          advertisement_id: advertisement_id,
          network_id: network_id,
          display_time: timestamp,
          duration_ms: duration_ms
        }.merge(options.slice(:device_id, :venue_metadata))
      end
    end
  end
end
