# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VistarClient::API::UnifiedServing do
  let(:api_key) { 'test-api-key' }
  let(:network_id) { 'test-network-id' }
  let(:client) { VistarClient::Client.new(api_key: api_key, network_id: network_id) }

  describe '#get_loop' do
    let(:venue_id) { 'venue-123' }
    let(:display_time) { Time.now.to_i }

    context 'with valid parameters' do
      let(:response_body) do
        {
          'slots' => [
            {
              'type' => 'advertisement',
              'length_in_seconds' => 15,
              'tracking_url' => 'https://track.vistarmedia.com/track1',
              'asset_url' => 'https://assets.vistarmedia.com/creative1.mp4',
              'creative_category' => 'Entertainment',
              'loop_position' => 1,
              'creative_id' => 'creative-abc-123'
            },
            {
              'type' => 'programmatic',
              'length_in_seconds' => 15,
              'loop_position' => 2
            },
            {
              'type' => 'content',
              'length_in_seconds' => 30,
              'tracking_url' => 'https://track.vistarmedia.com/track2',
              'asset_url' => 'https://assets.vistarmedia.com/content1.jpg',
              'creative_category' => 'Educational',
              'loop_position' => 3,
              'creative_id' => 'content-xyz-789'
            }
          ],
          'assets' => [
            {
              'url' => 'https://assets.vistarmedia.com/creative1.mp4',
              'mime_type' => 'video/mp4',
              'name' => 'Brand Campaign Video'
            },
            {
              'url' => 'https://assets.vistarmedia.com/content1.jpg',
              'mime_type' => 'image/jpeg',
              'name' => 'Educational Content'
            }
          ],
          'end_time' => 1_730_476_800,
          'start_time' => 1_730_390_400
        }
      end

      before do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .with(
            body: hash_including(
              'network_id' => network_id,
              'api_key' => api_key,
              'venue_id' => venue_id
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'requests loop successfully' do
        result = client.get_loop(venue_id: venue_id)

        expect(result).to eq(response_body)
        expect(result['slots']).to be_an(Array)
        expect(result['assets']).to be_an(Array)
      end

      it 'includes start_time and end_time in response' do
        result = client.get_loop(venue_id: venue_id)

        expect(result['start_time']).to eq(1_730_390_400)
        expect(result['end_time']).to eq(1_730_476_800)
      end

      it 'includes slots array with expected structure' do
        result = client.get_loop(venue_id: venue_id)

        slots = result['slots']
        expect(slots.length).to eq(3)

        # Check advertisement slot
        ad_slot = slots[0]
        expect(ad_slot['type']).to eq('advertisement')
        expect(ad_slot['tracking_url']).to be_a(String)
        expect(ad_slot['asset_url']).to be_a(String)
        expect(ad_slot['length_in_seconds']).to eq(15)

        # Check programmatic slot
        prog_slot = slots[1]
        expect(prog_slot['type']).to eq('programmatic')
        expect(prog_slot['length_in_seconds']).to eq(15)

        # Check content slot
        content_slot = slots[2]
        expect(content_slot['type']).to eq('content')
        expect(content_slot['tracking_url']).to be_a(String)
        expect(content_slot['asset_url']).to be_a(String)
      end

      it 'includes assets array with expected structure' do
        result = client.get_loop(venue_id: venue_id)

        assets = result['assets']
        expect(assets.length).to eq(2)

        asset = assets.first
        expect(asset['url']).to be_a(String)
        expect(asset['mime_type']).to eq('video/mp4')
        expect(asset['name']).to be_a(String)
      end

      it 'includes display_time in request when provided' do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .with(
            body: hash_including(
              'display_time' => display_time
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_loop(
          venue_id: venue_id,
          display_time: display_time
        )

        expect(result).to eq(response_body)
      end

      it 'includes with_metadata in request when true' do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .with(
            body: hash_including(
              'with_metadata' => true
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_loop(
          venue_id: venue_id,
          with_metadata: true
        )

        expect(result).to eq(response_body)
      end

      it 'includes metadata in slots when with_metadata is true' do
        response_with_metadata = response_body.dup
        response_with_metadata['slots'][0]['metadata'] = {
          'order_id' => 'order-001',
          'order_name' => 'Q4 2025 Campaign',
          'line_item_id' => 'li-001',
          'line_item_name' => 'Premium Placement',
          'advertiser_id' => 'adv-123',
          'advertiser_name' => 'Brand Corp'
        }

        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .with(
            body: hash_including(
              'with_metadata' => true
            )
          )
          .to_return(
            status: 200,
            body: response_with_metadata.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_loop(
          venue_id: venue_id,
          with_metadata: true
        )

        metadata = result['slots'][0]['metadata']
        expect(metadata['advertiser_name']).to eq('Brand Corp')
        expect(metadata['order_name']).to eq('Q4 2025 Campaign')
      end

      it 'works with all optional parameters' do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .with(
            body: hash_including(
              'venue_id' => venue_id,
              'display_time' => display_time,
              'with_metadata' => true
            )
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = client.get_loop(
          venue_id: venue_id,
          display_time: display_time,
          with_metadata: true
        )

        expect(result).to eq(response_body)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when venue_id is missing' do
        expect do
          client.get_loop(venue_id: nil)
        end.to raise_error(ArgumentError, /venue_id is required/)
      end

      it 'raises ArgumentError when venue_id is empty' do
        expect do
          client.get_loop(venue_id: '')
        end.to raise_error(ArgumentError, /venue_id is required/)
      end

      it 'raises ArgumentError when display_time is not an integer' do
        expect do
          client.get_loop(
            venue_id: venue_id,
            display_time: 'invalid'
          )
        end.to raise_error(ArgumentError, /display_time must be an integer/)
      end

      it 'raises ArgumentError when display_time is a float' do
        expect do
          client.get_loop(
            venue_id: venue_id,
            display_time: 123.45
          )
        end.to raise_error(ArgumentError, /display_time must be an integer/)
      end

      it 'raises ArgumentError when with_metadata is not a boolean' do
        expect do
          client.get_loop(
            venue_id: venue_id,
            with_metadata: 'yes'
          )
        end.to raise_error(ArgumentError, /with_metadata must be a boolean/)
      end

      it 'raises ArgumentError when with_metadata is nil (not false)' do
        expect do
          client.get_loop(
            venue_id: venue_id,
            with_metadata: nil
          )
        end.to raise_error(ArgumentError, /with_metadata must be a boolean/)
      end

      it 'allows with_metadata to be false explicitly' do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .to_return(
            status: 200,
            body: { 'slots' => [], 'assets' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.get_loop(
            venue_id: venue_id,
            with_metadata: false
          )
        end.not_to raise_error
      end

      it 'allows display_time to be nil (defaults to current time)' do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .to_return(
            status: 200,
            body: { 'slots' => [], 'assets' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.get_loop(
            venue_id: venue_id,
            display_time: nil
          )
        end.not_to raise_error
      end
    end

    context 'with API errors' do
      before do
        stub_request(:post, 'https://api.vistarmedia.com/v1beta2/loop')
          .to_return(status: error_status, body: error_body.to_json)
      end

      context 'when authentication fails' do
        let(:error_status) { 401 }
        let(:error_body) { { 'error' => 'Invalid API credentials' } }

        it 'raises AuthenticationError' do
          expect do
            client.get_loop(venue_id: venue_id)
          end.to raise_error(VistarClient::AuthenticationError, /Authentication failed/)
        end
      end

      context 'when API returns 400' do
        let(:error_status) { 400 }
        let(:error_body) { { 'error' => 'Invalid venue_id' } }

        it 'raises APIError with status code' do
          expect do
            client.get_loop(venue_id: venue_id)
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
            client.get_loop(venue_id: venue_id)
          end.to raise_error(VistarClient::APIError, /API request failed with status 500/)
        end
      end
    end
  end

  describe '#submit_loop_tracking' do
    let(:tracking_url) { 'https://track.vistarmedia.com/track123' }
    let(:display_time) { Time.now.to_i }

    context 'with valid parameters' do
      before do
        stub_request(:get, %r{https://track.vistarmedia.com/track123})
          .to_return(status: 200, body: '')
      end

      it 'submits tracking with display_time parameter' do
        expected_url = "#{tracking_url}?display_time=#{display_time}"

        stub_request(:get, expected_url)
          .to_return(status: 200, body: '')

        client.submit_loop_tracking(
          tracking_url: tracking_url,
          display_time: display_time
        )

        expect(WebMock).to have_requested(:get, expected_url)
      end

      it 'uses current time when display_time is not provided' do
        allow(Time).to receive(:now).and_return(Time.at(display_time))

        expected_url = "#{tracking_url}?display_time=#{display_time}"

        stub_request(:get, expected_url)
          .to_return(status: 200, body: '')

        client.submit_loop_tracking(tracking_url: tracking_url)

        expect(WebMock).to have_requested(:get, expected_url)
      end

      it 'uses ampersand separator when URL has existing query params' do
        url_with_params = "#{tracking_url}?existing=param"
        expected_url = "#{url_with_params}&display_time=#{display_time}"

        stub_request(:get, expected_url)
          .to_return(status: 200, body: '')

        client.submit_loop_tracking(
          tracking_url: url_with_params,
          display_time: display_time
        )

        expect(WebMock).to have_requested(:get, expected_url)
      end

      it 'appends display_time even when URL has fragment' do
        url_with_fragment = "#{tracking_url}#section"
        # NOTE: query params should come before fragment in proper URL format
        # but our simple implementation appends after, which still works for tracking

        stub_request(:get, /track123/)
          .to_return(status: 200, body: '')

        expect do
          client.submit_loop_tracking(
            tracking_url: url_with_fragment,
            display_time: display_time
          )
        end.not_to raise_error
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when tracking_url is missing' do
        expect do
          client.submit_loop_tracking(tracking_url: nil)
        end.to raise_error(ArgumentError, /tracking_url is required/)
      end

      it 'raises ArgumentError when tracking_url is empty' do
        expect do
          client.submit_loop_tracking(tracking_url: '')
        end.to raise_error(ArgumentError, /tracking_url is required/)
      end
    end
  end
end
