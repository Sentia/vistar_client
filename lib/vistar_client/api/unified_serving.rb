# frozen_string_literal: true

require_relative 'base'

module VistarClient
  module API
    # Unified Ad Serving API for loop-based content scheduling.
    #
    # This module implements the Vistar Media Unified Ad Serving API which provides
    # scheduled loops of content for digital signage playlists. It combines direct
    # scheduled content, programmatic ad opportunities, and loop-based content into
    # a unified sequence.
    #
    # The API returns a loop of slots (typically 24 hours) that can be played repeatedly.
    # Each slot has a type: advertisement, content, or programmatic.
    #
    # @see https://help.vistarmedia.com/hc/en-us/articles/360056689132-Unified-Ad-Serving-API
    module UnifiedServing
      include Base

      # Get scheduled loop of content slots for digital signage playlist.
      #
      # Returns a sequence of slots (advertisement, content, programmatic) that form
      # a repeating loop until end_time. The response includes both slots[] and assets[]
      # for efficient pre-caching.
      #
      # Recommended: Request new loops at least every 30 minutes, even if end_time is
      # far in the future.
      #
      # @param venue_id [String] venue identifier making the request (required)
      # @param display_time [Integer, nil] loop start time in UTC epoch seconds (optional, defaults to now)
      # @param with_metadata [Boolean] include order/advertiser metadata in response (optional, default: false)
      #
      # @return [Hash] response containing slots[], assets[], start_time, end_time
      #   - slots: Array of slot objects with type, tracking_url, asset_url, length_in_seconds
      #   - assets: Array of unique assets referenced by slots for pre-caching
      #   - start_time: Loop start time (epoch seconds)
      #   - end_time: Loop end time (epoch seconds, typically +24 hours)
      #
      # @raise [ArgumentError] if required parameters are missing or invalid
      # @raise [AuthenticationError] if API key is invalid (401)
      # @raise [APIError] for other API errors (4xx/5xx)
      # @raise [ConnectionError] for network failures
      #
      # @example Basic loop request
      #   loop_data = client.get_loop(venue_id: 'venue-123')
      #
      #   loop_data['slots'].each do |slot|
      #     case slot['type']
      #     when 'advertisement', 'content'
      #       play_asset(slot['asset_url'])
      #       client.submit_loop_tracking(
      #         tracking_url: slot['tracking_url'],
      #         display_time: Time.now.to_i
      #       )
      #     when 'programmatic'
      #       ad = client.request_ad(...)
      #       # handle programmatic ad request
      #     end
      #   end
      #
      # @example Loop with metadata for reporting
      #   loop_data = client.get_loop(
      #     venue_id: 'venue-123',
      #     with_metadata: true
      #   )
      #
      #   loop_data['slots'].each do |slot|
      #     if slot['metadata']
      #       puts "Advertiser: #{slot['metadata']['advertiser_name']}"
      #     end
      #   end
      #
      # @example Future loop scheduling (up to 10 days)
      #   tomorrow = Time.now.to_i + 86400
      #   future_loop = client.get_loop(
      #     venue_id: 'venue-123',
      #     display_time: tomorrow
      #   )
      def get_loop(venue_id:, display_time: nil, with_metadata: false)
        validate_get_loop_params!(venue_id, display_time, with_metadata)

        payload = build_get_loop_payload(venue_id, display_time, with_metadata)

        response = connection.post('/v1beta2/loop', payload)
        response.body
      end

      # Submit tracking URL for loop slot completion.
      #
      # Convenience method to hit tracking URLs with proper display_time appending.
      # Always appends display_time query parameter for accurate tracking, even if
      # the slot was displayed at a different time than scheduled.
      #
      # Tracking URLs don't expire, making this suitable for offline devices that
      # may submit tracking data later (up to 30 days in the past).
      #
      # @param tracking_url [String] the tracking URL from slot (required)
      # @param display_time [Integer, nil] when slot was actually displayed in UTC epoch seconds
      #   (optional, defaults to current time)
      #
      # @return [Faraday::Response] tracking response
      #
      # @raise [ArgumentError] if tracking_url is missing or empty
      # @raise [ConnectionError] for network failures
      #
      # @example Submit tracking after slot completion
      #   slot = loop_data['slots'].first
      #   play_asset(slot['asset_url'])
      #
      #   client.submit_loop_tracking(
      #     tracking_url: slot['tracking_url'],
      #     display_time: Time.now.to_i
      #   )
      #
      # @example Submit tracking with different display time (offline scenario)
      #   actual_play_time = Time.now.to_i - 3600 # 1 hour ago
      #   client.submit_loop_tracking(
      #     tracking_url: slot['tracking_url'],
      #     display_time: actual_play_time
      #   )
      def submit_loop_tracking(tracking_url:, display_time: nil)
        raise ArgumentError, 'tracking_url is required' if tracking_url.nil? || tracking_url.to_s.empty?

        display_time ||= Time.now.to_i

        # Append display_time query parameter
        separator = tracking_url.include?('?') ? '&' : '?'
        url = "#{tracking_url}#{separator}display_time=#{display_time}"

        # Use Connection#get_request for tracking URLs
        connection.get_request(url)
      end

      private

      # Validate get_loop parameters.
      #
      # @param venue_id [String] the venue ID
      # @param display_time [Integer, nil] the display time in epoch seconds
      # @param with_metadata [Boolean] whether to include metadata
      #
      # @raise [ArgumentError] if any parameter is invalid
      #
      # @return [void]
      def validate_get_loop_params!(venue_id, display_time, with_metadata)
        raise ArgumentError, 'venue_id is required' if venue_id.nil? || venue_id.to_s.empty?

        if display_time && !display_time.is_a?(Integer)
          raise ArgumentError, 'display_time must be an integer (epoch seconds)'
        end

        return if [true, false].include?(with_metadata)

        raise ArgumentError, 'with_metadata must be a boolean'
      end

      # Build payload for get_loop request.
      #
      # @param venue_id [String] the venue ID
      # @param display_time [Integer, nil] the display time
      # @param with_metadata [Boolean] whether to include metadata
      #
      # @return [Hash] the request payload
      def build_get_loop_payload(venue_id, display_time, with_metadata)
        payload = {
          venue_id: venue_id,
          network_id: network_id,
          api_key: api_key
        }

        payload[:display_time] = display_time if display_time
        payload[:with_metadata] = with_metadata if with_metadata

        payload
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
