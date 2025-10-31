# frozen_string_literal: true

RSpec.describe VistarClient::Client do
  let(:api_key) { 'test-api-key-123' }
  let(:network_id) { 'test-network-456' }
  let(:valid_params) { { api_key: api_key, network_id: network_id } }

  describe '#initialize' do
    context 'with valid credentials' do
      it 'creates a client successfully' do
        client = described_class.new(**valid_params)

        expect(client).to be_a(described_class)
        expect(client.api_key).to eq(api_key)
        expect(client.network_id).to eq(network_id)
      end

      it 'uses default api_base_url when not provided' do
        client = described_class.new(**valid_params)

        expect(client.api_base_url).to eq(VistarClient::Client::DEFAULT_API_BASE_URL)
      end

      it 'uses default timeout when not provided' do
        client = described_class.new(**valid_params)

        expect(client.timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
      end

      it 'accepts custom api_base_url' do
        custom_url = 'https://custom.api.example.com'
        client = described_class.new(**valid_params, api_base_url: custom_url)

        expect(client.api_base_url).to eq(custom_url)
      end

      it 'accepts custom timeout' do
        custom_timeout = 30
        client = described_class.new(**valid_params, timeout: custom_timeout)

        expect(client.timeout).to eq(custom_timeout)
      end
    end

    context 'with invalid credentials' do
      it 'raises ArgumentError when api_key is nil' do
        expect do
          described_class.new(api_key: nil, network_id: network_id)
        end.to raise_error(ArgumentError, /api_key is required/)
      end

      it 'raises ArgumentError when api_key is empty' do
        expect do
          described_class.new(api_key: '', network_id: network_id)
        end.to raise_error(ArgumentError, /api_key is required/)
      end

      it 'raises ArgumentError when network_id is nil' do
        expect do
          described_class.new(api_key: api_key, network_id: nil)
        end.to raise_error(ArgumentError, /network_id is required/)
      end

      it 'raises ArgumentError when network_id is empty' do
        expect do
          described_class.new(api_key: api_key, network_id: '')
        end.to raise_error(ArgumentError, /network_id is required/)
      end

      it 'raises ArgumentError when both credentials are missing' do
        expect do
          described_class.new(api_key: nil, network_id: nil)
        end.to raise_error(ArgumentError, /api_key is required/)
      end
    end
  end

  describe '#connection' do
    let(:client) { described_class.new(**valid_params) }
    let(:faraday_connection) { client.send(:connection).get }

    it 'returns a Connection wrapper' do
      connection = client.send(:connection)

      expect(connection).to be_a(VistarClient::Connection)
    end

    it 'wraps a Faraday::Connection instance' do
      expect(faraday_connection).to be_a(Faraday::Connection)
    end

    it 'caches the connection instance' do
      connection1 = client.send(:connection)
      connection2 = client.send(:connection)

      expect(connection1).to be(connection2)
    end

    it 'uses the configured api_base_url' do
      expect(faraday_connection.url_prefix.to_s).to eq("#{VistarClient::Client::DEFAULT_API_BASE_URL}/")
    end

    it 'configures timeout options' do
      expect(faraday_connection.options.timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
      expect(faraday_connection.options.open_timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
    end

    it 'sets Authorization header with Bearer token' do
      expect(faraday_connection.headers['Authorization']).to eq("Bearer #{api_key}")
    end

    it 'sets Accept and Content-Type headers' do
      expect(faraday_connection.headers['Accept']).to eq('application/json')
      expect(faraday_connection.headers['Content-Type']).to eq('application/json')
    end

    it 'includes JSON request middleware' do
      middleware = faraday_connection.builder.handlers

      expect(middleware).to include(Faraday::Request::Json)
    end

    it 'includes retry middleware' do
      middleware = faraday_connection.builder.handlers

      expect(middleware).to include(Faraday::Retry::Middleware)
    end

    it 'includes JSON response middleware' do
      middleware = faraday_connection.builder.handlers

      expect(middleware).to include(Faraday::Response::Json)
    end

    it 'includes error handler middleware' do
      middleware = faraday_connection.builder.handlers

      expect(middleware).to include(VistarClient::Middleware::ErrorHandler)
    end

    context 'with custom api_base_url' do
      let(:custom_url) { 'https://staging.api.example.com' }
      let(:client) { described_class.new(**valid_params, api_base_url: custom_url) }
      let(:faraday_connection) { client.send(:connection).get }

      it 'uses the custom URL' do
        expect(faraday_connection.url_prefix.to_s).to eq("#{custom_url}/")
      end
    end

    context 'with custom timeout' do
      let(:custom_timeout) { 45 }
      let(:client) { described_class.new(**valid_params, timeout: custom_timeout) }
      let(:faraday_connection) { client.send(:connection).get }

      it 'uses the custom timeout' do
        expect(faraday_connection.options.timeout).to eq(custom_timeout)
        expect(faraday_connection.options.open_timeout).to eq(custom_timeout)
      end
    end

    context 'with VISTAR_DEBUG enabled' do
      before { ENV['VISTAR_DEBUG'] = 'true' }
      after { ENV.delete('VISTAR_DEBUG') }

      it 'includes logger middleware' do
        faraday_connection = client.send(:connection).get
        middleware = faraday_connection.builder.handlers

        expect(middleware).to include(Faraday::Response::Logger)
      end
    end

    context 'without VISTAR_DEBUG' do
      before { ENV.delete('VISTAR_DEBUG') }

      it 'does not include logger middleware' do
        faraday_connection = client.send(:connection).get
        middleware = faraday_connection.builder.handlers

        expect(middleware).not_to include(Faraday::Response::Logger)
      end
    end
  end

  describe 'attr_readers' do
    let(:client) { described_class.new(**valid_params) }

    it 'provides read access to api_key' do
      expect(client.api_key).to eq(api_key)
    end

    it 'provides read access to network_id' do
      expect(client.network_id).to eq(network_id)
    end

    it 'provides read access to api_base_url' do
      expect(client.api_base_url).to eq(VistarClient::Client::DEFAULT_API_BASE_URL)
    end

    it 'provides read access to timeout' do
      expect(client.timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
    end

    it 'does not allow writing to api_key' do
      expect { client.api_key = 'new-key' }.to raise_error(NoMethodError)
    end

    it 'does not allow writing to network_id' do
      expect { client.network_id = 'new-id' }.to raise_error(NoMethodError)
    end
  end

  describe 'constants' do
    it 'defines DEFAULT_API_BASE_URL' do
      expect(VistarClient::Client::DEFAULT_API_BASE_URL).to eq('https://api.vistarmedia.com')
    end

    it 'defines DEFAULT_TIMEOUT' do
      expect(VistarClient::Client::DEFAULT_TIMEOUT).to eq(10)
    end
  end

  describe '#request_ad' do
    let(:client) { described_class.new(**valid_params) }
    let(:device_id) { 'device-123' }
    let(:display_area) { { width: 1920, height: 1080 } }
    let(:latitude) { 37.7749 }
    let(:longitude) { -122.4194 }

    let(:ad_response) do
      {
        'advertisement_id' => 'ad-789',
        'creative_url' => 'https://cdn.example.com/ad.jpg',
        'duration_ms' => 15_000
      }
    end

    context 'with valid parameters' do
      before do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_ad')
          .with(
            body: hash_including(
              device_id: device_id,
              network_id: network_id,
              display_area: display_area,
              latitude: latitude,
              longitude: longitude
            ),
            headers: { 'Authorization' => "Bearer #{api_key}" }
          )
          .to_return(status: 200, body: ad_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'requests an ad successfully' do
        response = client.request_ad(
          device_id: device_id,
          display_area: display_area,
          latitude: latitude,
          longitude: longitude
        )

        expect(response).to eq(ad_response)
      end

      it 'includes optional parameters' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_ad')
          .with(
            body: hash_including(
              duration_ms: 15_000,
              device_type: 'billboard'
            )
          )
          .to_return(status: 200, body: ad_response.to_json, headers: { 'Content-Type' => 'application/json' })

        response = client.request_ad(
          device_id: device_id,
          display_area: display_area,
          latitude: latitude,
          longitude: longitude,
          duration_ms: 15_000,
          device_type: 'billboard'
        )

        expect(response).to eq(ad_response)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when device_id is missing' do
        expect do
          client.request_ad(
            device_id: nil,
            display_area: display_area,
            latitude: latitude,
            longitude: longitude
          )
        end.to raise_error(ArgumentError, /device_id is required/)
      end

      it 'raises ArgumentError when display_area is not a Hash' do
        expect do
          client.request_ad(
            device_id: device_id,
            display_area: 'invalid',
            latitude: latitude,
            longitude: longitude
          )
        end.to raise_error(ArgumentError, /display_area is required and must be a Hash/)
      end

      it 'raises ArgumentError when display_area missing width' do
        expect do
          client.request_ad(
            device_id: device_id,
            display_area: { height: 1080 },
            latitude: latitude,
            longitude: longitude
          )
        end.to raise_error(ArgumentError, /display_area must include :width and :height/)
      end

      it 'raises ArgumentError when latitude is invalid' do
        expect do
          client.request_ad(
            device_id: device_id,
            display_area: display_area,
            latitude: 100,
            longitude: longitude
          )
        end.to raise_error(ArgumentError, /latitude must be between -90 and 90/)
      end

      it 'raises ArgumentError when longitude is invalid' do
        expect do
          client.request_ad(
            device_id: device_id,
            display_area: display_area,
            latitude: latitude,
            longitude: 200
          )
        end.to raise_error(ArgumentError, /longitude must be between -180 and 180/)
      end
    end

    context 'with API errors' do
      it 'raises AuthenticationError on 401' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_ad')
          .to_return(
            status: 401,
            body: JSON.generate({ 'error' => 'Invalid API key' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.request_ad(
            device_id: device_id,
            display_area: display_area,
            latitude: latitude,
            longitude: longitude
          )
        end.to raise_error(VistarClient::AuthenticationError, /Invalid API key/)
      end

      it 'raises APIError on 400' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/get_ad')
          .to_return(
            status: 400,
            body: JSON.generate({ 'error' => 'Bad request' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.request_ad(
            device_id: device_id,
            display_area: display_area,
            latitude: latitude,
            longitude: longitude
          )
        end.to raise_error(VistarClient::APIError) do |error|
          expect(error.status_code).to eq(400)
          expect(error.message).to include('Bad request')
        end
      end
    end
  end

  describe '#submit_proof_of_play' do
    let(:client) { described_class.new(**valid_params) }
    let(:advertisement_id) { 'ad-789' }
    let(:display_time) { Time.new(2025, 10, 31, 12, 0, 0, '+00:00') }
    let(:duration_ms) { 15_000 }

    let(:pop_response) do
      {
        'status' => 'success',
        'proof_id' => 'proof-456'
      }
    end

    context 'with valid parameters' do
      before do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/proof_of_play')
          .with(
            body: hash_including(
              advertisement_id: advertisement_id,
              network_id: network_id,
              display_time: display_time.iso8601,
              duration_ms: duration_ms
            ),
            headers: { 'Authorization' => "Bearer #{api_key}" }
          )
          .to_return(status: 200, body: pop_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'submits proof of play successfully' do
        response = client.submit_proof_of_play(
          advertisement_id: advertisement_id,
          display_time: display_time,
          duration_ms: duration_ms
        )

        expect(response).to eq(pop_response)
      end

      it 'includes optional parameters' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/proof_of_play')
          .with(
            body: hash_including(
              device_id: 'device-123',
              venue_metadata: { venue_id: 'venue-1' }
            )
          )
          .to_return(status: 200, body: pop_response.to_json, headers: { 'Content-Type' => 'application/json' })

        response = client.submit_proof_of_play(
          advertisement_id: advertisement_id,
          display_time: display_time,
          duration_ms: duration_ms,
          device_id: 'device-123',
          venue_metadata: { venue_id: 'venue-1' }
        )

        expect(response).to eq(pop_response)
      end

      it 'handles string display_time' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/proof_of_play')
          .with(
            body: hash_including(
              display_time: '2025-10-31T12:00:00Z'
            )
          )
          .to_return(status: 200, body: pop_response.to_json, headers: { 'Content-Type' => 'application/json' })

        response = client.submit_proof_of_play(
          advertisement_id: advertisement_id,
          display_time: '2025-10-31T12:00:00Z',
          duration_ms: duration_ms
        )

        expect(response).to eq(pop_response)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when advertisement_id is missing' do
        expect do
          client.submit_proof_of_play(
            advertisement_id: nil,
            display_time: display_time,
            duration_ms: duration_ms
          )
        end.to raise_error(ArgumentError, /advertisement_id is required/)
      end

      it 'raises ArgumentError when display_time is missing' do
        expect do
          client.submit_proof_of_play(
            advertisement_id: advertisement_id,
            display_time: nil,
            duration_ms: duration_ms
          )
        end.to raise_error(ArgumentError, /display_time is required/)
      end

      it 'raises ArgumentError when duration_ms is not a positive integer' do
        expect do
          client.submit_proof_of_play(
            advertisement_id: advertisement_id,
            display_time: display_time,
            duration_ms: -100
          )
        end.to raise_error(ArgumentError, /duration_ms is required and must be a positive integer/)
      end

      it 'raises ArgumentError when duration_ms is not an integer' do
        expect do
          client.submit_proof_of_play(
            advertisement_id: advertisement_id,
            display_time: display_time,
            duration_ms: 'invalid'
          )
        end.to raise_error(ArgumentError, /duration_ms is required and must be a positive integer/)
      end
    end

    context 'with API errors' do
      it 'raises AuthenticationError on 401' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/proof_of_play')
          .to_return(
            status: 401,
            body: JSON.generate({ 'error' => 'Invalid API key' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.submit_proof_of_play(
            advertisement_id: advertisement_id,
            display_time: display_time,
            duration_ms: duration_ms
          )
        end.to raise_error(VistarClient::AuthenticationError)
      end

      it 'raises APIError on 500' do
        stub_request(:post, 'https://api.vistarmedia.com/api/v1/proof_of_play')
          .to_return(
            status: 500,
            body: JSON.generate({ 'error' => 'Internal server error' }),
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.submit_proof_of_play(
            advertisement_id: advertisement_id,
            display_time: display_time,
            duration_ms: duration_ms
          )
        end.to raise_error(VistarClient::APIError) do |error|
          expect(error.status_code).to eq(500)
        end
      end
    end
  end
end
