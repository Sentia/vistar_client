# frozen_string_literal: true

require_relative 'vistar_client/version'
require_relative 'vistar_client/error'
require_relative 'vistar_client/client'

# Ruby client library for the Vistar Media API.
#
# This gem provides a simple, object-oriented interface to interact with
# the Vistar Media programmatic advertising platform.
#
# @example Quick start
#   require 'vistar_client'
#
#   # Initialize the client
#   client = VistarClient::Client.new(
#     api_key: ENV['VISTAR_API_KEY'],
#     network_id: ENV['VISTAR_NETWORK_ID']
#   )
#
#   # Request an ad
#   ad = client.request_ad(
#     device_id: 'device-123',
#     display_area: { width: 1920, height: 1080 },
#     latitude: 37.7749,
#     longitude: -122.4194,
#     duration_ms: 15_000
#   )
#
#   # Submit proof of play
#   client.submit_proof_of_play(
#     advertisement_id: ad['id'],
#     display_time: Time.now,
#     duration_ms: 15_000
#   )
#
# @see VistarClient::Client
# @see https://help.vistarmedia.com/hc/en-us/articles/225058628-Ad-Serving-API
module VistarClient
  class Error < StandardError; end
end
