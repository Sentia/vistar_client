# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VistarClient::API::CreativeCaching do
  let(:api_key) { 'test-api-key' }
  let(:network_id) { 'test-network-id' }
  let(:client) { VistarClient::Client.new(api_key: api_key, network_id: network_id) }

  describe '#get_asset' do
    let(:device_id) { 'device-123' }
    let(:venue_id) { 'venue-456' }
    let(:display_time) { Time.now.to_i }
    let(:display_area) do
      {
        id: 'display-0',
        width: 1920,
        height: 1080,
        supported_media: ['image/jpeg', 'video/mp4'],
        allow_audio: false
      }
    end

    context 'with valid parameters' do
      let(:response_body) do
        {
          'asset' => [
            {
              'asset_id' => 'asset-1',
              'creative_id' => 'creative-1',
              'order_id' => 'Q1_2025_001',
              'campaign_id' => 'campaign-1',
              'asset_url' => 'https://example.com/asset.jpg',
              'width' => 1920,
              'height' => 1080,
              'mime_type' => 'image/jpeg',
              'length_in_seconds' => 15,
              'length_in_milliseconds' => 15_000,
              'creative_category' => 'Entertainment',
              'advertiser' => 'Test Advertiser',
              'creative_name' => 'Test Creative'
            }
          ]
        }
      end

      before do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_asset/json')
          .with(
            body: hash_including(
              'network_id' => network_id,
              'api_key' => api_key,
              'device_id' => device_id,
              'venue_id' => venue_id,
              'display_time' => display_time,
              'display_area' => [display_area],
              'direct_connection' => false
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'requests creative assets successfully' do
        result = client.get_asset(
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: display_area
        )

        expect(result).to eq(response_body)
        expect(result['asset']).to be_an(Array)
        expect(result['asset'].first['asset_id']).to eq('asset-1')
      end

      it 'includes asset metadata in response' do
        result = client.get_asset(
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: display_area
        )

        asset = result['asset'].first
        expect(asset['asset_url']).to eq('https://example.com/asset.jpg')
        expect(asset['mime_type']).to eq('image/jpeg')
        expect(asset['advertiser']).to eq('Test Advertiser')
        expect(asset['length_in_seconds']).to eq(15)
      end

      it 'includes optional device_attribute parameter' do
        device_attributes = [{ name: 'location', value: 'lobby' }]

        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_asset/json')
          .with(
            body: hash_including(
              'device_attribute' => device_attributes
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_asset(
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: display_area,
          device_attribute: device_attributes
        )

        expect(result).to eq(response_body)
      end

      it 'includes optional latitude and longitude' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_asset/json')
          .with(
            body: hash_including(
              'latitude' => 37.7749,
              'longitude' => -122.4194
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_asset(
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: display_area,
          latitude: 37.7749,
          longitude: -122.4194
        )

        expect(result).to eq(response_body)
      end

      it 'wraps display_area in an array' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_asset/json')
          .with(
            body: hash_including(
              'display_area' => [display_area]
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_asset(
          device_id: device_id,
          venue_id: venue_id,
          display_time: display_time,
          display_area: display_area
        )

        expect(result).to eq(response_body)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when device_id is missing' do
        expect do
          client.get_asset(
            device_id: nil,
            venue_id: venue_id,
            display_time: display_time,
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /device_id is required/)
      end

      it 'raises ArgumentError when device_id is empty' do
        expect do
          client.get_asset(
            device_id: '',
            venue_id: venue_id,
            display_time: display_time,
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /device_id is required/)
      end

      it 'raises ArgumentError when venue_id is missing' do
        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: nil,
            display_time: display_time,
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /venue_id is required/)
      end

      it 'raises ArgumentError when venue_id is empty' do
        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: '',
            display_time: display_time,
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /venue_id is required/)
      end

      it 'raises ArgumentError when display_time is missing' do
        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: nil,
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /display_time is required/)
      end

      it 'raises ArgumentError when display_time is not an integer' do
        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: 'invalid',
            display_area: display_area
          )
        end.to raise_error(ArgumentError, /display_time must be an integer/)
      end

      it 'raises ArgumentError when display_area is not a Hash' do
        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: 'invalid'
          )
        end.to raise_error(ArgumentError, /display_area is required and must be a Hash/)
      end

      it 'raises ArgumentError when display_area missing id' do
        invalid_area = display_area.dup
        invalid_area.delete(:id)

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :id/)
      end

      it 'raises ArgumentError when display_area missing width' do
        invalid_area = display_area.dup
        invalid_area.delete(:width)

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :width/)
      end

      it 'raises ArgumentError when display_area missing height' do
        invalid_area = display_area.dup
        invalid_area.delete(:height)

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :height/)
      end

      it 'raises ArgumentError when display_area missing supported_media' do
        invalid_area = display_area.dup
        invalid_area.delete(:supported_media)

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :supported_media array/)
      end

      it 'raises ArgumentError when supported_media is not an array' do
        invalid_area = display_area.dup
        invalid_area[:supported_media] = 'invalid'

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :supported_media array/)
      end

      it 'raises ArgumentError when supported_media is empty array' do
        invalid_area = display_area.dup
        invalid_area[:supported_media] = []

        expect do
          client.get_asset(
            device_id: device_id,
            venue_id: venue_id,
            display_time: display_time,
            display_area: invalid_area
          )
        end.to raise_error(ArgumentError, /display_area must include :supported_media array/)
      end
    end

    context 'with API errors' do
      before do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_asset/json')
          .to_return(status: error_status, body: error_body.to_json)
      end

      context 'when authentication fails' do
        let(:error_status) { 401 }
        let(:error_body) { { 'error' => 'Invalid API credentials' } }

        it 'raises AuthenticationError' do
          expect do
            client.get_asset(
              device_id: device_id,
              venue_id: venue_id,
              display_time: display_time,
              display_area: display_area
            )
          end.to raise_error(VistarClient::AuthenticationError, /Authentication failed/)
        end
      end

      context 'when API returns 400' do
        let(:error_status) { 400 }
        let(:error_body) { { 'error' => 'Invalid request parameters' } }

        it 'raises APIError with status code' do
          expect do
            client.get_asset(
              device_id: device_id,
              venue_id: venue_id,
              display_time: display_time,
              display_area: display_area
            )
          end.to(raise_error(VistarClient::APIError) do |error|
            expect(error.message).to include('API request failed with status 400')
            expect(error.status_code).to eq(400)
          end)
        end
      end

      context 'when API returns 500' do
        let(:error_status) { 500 }
        let(:error_body) { { 'error' => 'Internal server error' } }

        it 'raises APIError' do
          expect do
            client.get_asset(
              device_id: device_id,
              venue_id: venue_id,
              display_time: display_time,
              display_area: display_area
            )
          end.to raise_error(VistarClient::APIError, /API request failed with status 500/)
        end
      end
    end
  end
end
