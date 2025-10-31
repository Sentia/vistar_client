# frozen_string_literal: true

require 'spec_helper'
require 'vistar_client/connection'

RSpec.describe VistarClient::Connection do
  let(:api_key) { 'test-api-key' }
  let(:api_base_url) { 'https://api.vistarmedia.com' }
  let(:timeout) { 10 }

  let(:connection) do
    described_class.new(
      api_key: api_key,
      api_base_url: api_base_url,
      timeout: timeout
    )
  end

  describe '#initialize' do
    it 'stores the api_key' do
      expect(connection.api_key).to eq(api_key)
    end

    it 'stores the api_base_url' do
      expect(connection.api_base_url).to eq(api_base_url)
    end

    it 'stores the timeout' do
      expect(connection.timeout).to eq(timeout)
    end
  end

  describe '#get' do
    it 'returns a Faraday::Connection' do
      expect(connection.get).to be_a(Faraday::Connection)
    end

    it 'caches the connection' do
      conn1 = connection.get
      conn2 = connection.get

      expect(conn1).to be(conn2)
    end

    it 'configures the base URL' do
      expect(connection.get.url_prefix.to_s).to eq("#{api_base_url}/")
    end

    it 'sets authorization header' do
      expect(connection.get.headers['Authorization']).to eq("Bearer #{api_key}")
    end

    it 'sets content-type headers' do
      expect(connection.get.headers['Accept']).to eq('application/json')
      expect(connection.get.headers['Content-Type']).to eq('application/json')
    end

    it 'configures timeout options' do
      faraday_conn = connection.get

      expect(faraday_conn.options.timeout).to eq(timeout)
      expect(faraday_conn.options.open_timeout).to eq(timeout)
    end
  end

  describe '#to_faraday' do
    it 'is an alias for #get' do
      expect(connection.to_faraday).to eq(connection.get)
    end
  end

  describe '#post' do
    let(:path) { '/api/v1/test' }
    let(:payload) { { key: 'value' } }
    let(:mock_response) { double('response', body: { result: 'success' }) }

    before do
      allow(connection.get).to receive(:post).with(path, payload).and_return(mock_response)
    end

    it 'delegates to the Faraday connection' do
      result = connection.post(path, payload)

      expect(result).to eq(mock_response)
      expect(connection.get).to have_received(:post).with(path, payload)
    end
  end

  describe '#get_request' do
    let(:path) { '/api/v1/test' }
    let(:params) { { query: 'param' } }
    let(:mock_response) { double('response', body: { result: 'success' }) }

    before do
      allow(connection.get).to receive(:get).with(path, params).and_return(mock_response)
    end

    it 'delegates to the Faraday connection' do
      result = connection.get_request(path, params)

      expect(result).to eq(mock_response)
      expect(connection.get).to have_received(:get).with(path, params)
    end

    it 'works with empty params' do
      allow(connection.get).to receive(:get).with(path, {}).and_return(mock_response)

      result = connection.get_request(path)

      expect(result).to eq(mock_response)
    end
  end

  describe 'method delegation' do
    it 'delegates builder to Faraday connection' do
      expect(connection.builder).to be_a(Faraday::RackBuilder)
    end

    it 'responds to Faraday connection methods' do
      expect(connection).to respond_to(:url_prefix)
      expect(connection).to respond_to(:options)
      expect(connection).to respond_to(:headers)
    end

    it 'raises NoMethodError for unknown methods' do
      expect { connection.nonexistent_method }.to raise_error(NoMethodError)
    end
  end

  describe 'middleware configuration' do
    let(:faraday_conn) { connection.get }
    let(:middleware) { faraday_conn.builder.handlers }

    it 'includes JSON request middleware' do
      expect(middleware).to include(Faraday::Request::Json)
    end

    it 'includes retry middleware' do
      expect(middleware).to include(Faraday::Retry::Middleware)
    end

    it 'includes error handler middleware' do
      expect(middleware).to include(VistarClient::Middleware::ErrorHandler)
    end

    it 'includes JSON response middleware' do
      expect(middleware).to include(Faraday::Response::Json)
    end

    context 'with VISTAR_DEBUG enabled' do
      before { ENV['VISTAR_DEBUG'] = 'true' }
      after { ENV.delete('VISTAR_DEBUG') }

      it 'includes logger middleware' do
        # Need to create a new connection to pick up the ENV var
        debug_connection = described_class.new(
          api_key: api_key,
          api_base_url: api_base_url,
          timeout: timeout
        )

        middleware = debug_connection.get.builder.handlers
        expect(middleware).to include(Faraday::Response::Logger)
      end
    end

    context 'without VISTAR_DEBUG' do
      before { ENV.delete('VISTAR_DEBUG') }

      it 'does not include logger middleware' do
        expect(middleware).not_to include(Faraday::Response::Logger)
      end
    end
  end
end
