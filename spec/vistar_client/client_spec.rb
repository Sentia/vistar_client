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

    it 'returns a Faraday::Connection instance' do
      connection = client.send(:connection)

      expect(connection).to be_a(Faraday::Connection)
    end

    it 'caches the connection instance' do
      connection1 = client.send(:connection)
      connection2 = client.send(:connection)

      expect(connection1).to be(connection2)
    end

    it 'uses the configured api_base_url' do
      connection = client.send(:connection)

      expect(connection.url_prefix.to_s).to eq("#{VistarClient::Client::DEFAULT_API_BASE_URL}/")
    end

    it 'configures timeout options' do
      connection = client.send(:connection)

      expect(connection.options.timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
      expect(connection.options.open_timeout).to eq(VistarClient::Client::DEFAULT_TIMEOUT)
    end

    it 'sets Authorization header with Bearer token' do
      connection = client.send(:connection)

      expect(connection.headers['Authorization']).to eq("Bearer #{api_key}")
    end

    it 'sets Accept and Content-Type headers' do
      connection = client.send(:connection)

      expect(connection.headers['Accept']).to eq('application/json')
      expect(connection.headers['Content-Type']).to eq('application/json')
    end

    it 'includes JSON request middleware' do
      connection = client.send(:connection)
      middleware = connection.builder.handlers

      expect(middleware).to include(Faraday::Request::Json)
    end

    it 'includes retry middleware' do
      connection = client.send(:connection)
      middleware = connection.builder.handlers

      expect(middleware).to include(Faraday::Retry::Middleware)
    end

    it 'includes JSON response middleware' do
      connection = client.send(:connection)
      middleware = connection.builder.handlers

      expect(middleware).to include(Faraday::Response::Json)
    end

    context 'with custom api_base_url' do
      let(:custom_url) { 'https://staging.api.example.com' }
      let(:client) { described_class.new(**valid_params, api_base_url: custom_url) }

      it 'uses the custom URL' do
        connection = client.send(:connection)

        expect(connection.url_prefix.to_s).to eq("#{custom_url}/")
      end
    end

    context 'with custom timeout' do
      let(:custom_timeout) { 45 }
      let(:client) { described_class.new(**valid_params, timeout: custom_timeout) }

      it 'uses the custom timeout' do
        connection = client.send(:connection)

        expect(connection.options.timeout).to eq(custom_timeout)
        expect(connection.options.open_timeout).to eq(custom_timeout)
      end
    end

    context 'with VISTAR_DEBUG enabled' do
      before { ENV['VISTAR_DEBUG'] = 'true' }
      after { ENV.delete('VISTAR_DEBUG') }

      it 'includes logger middleware' do
        connection = client.send(:connection)
        middleware = connection.builder.handlers

        expect(middleware).to include(Faraday::Response::Logger)
      end
    end

    context 'without VISTAR_DEBUG' do
      before { ENV.delete('VISTAR_DEBUG') }

      it 'does not include logger middleware' do
        connection = client.send(:connection)
        middleware = connection.builder.handlers

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
end
