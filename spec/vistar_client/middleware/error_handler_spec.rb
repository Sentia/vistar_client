# frozen_string_literal: true

require 'spec_helper'
require 'vistar_client/middleware/error_handler'

RSpec.describe VistarClient::Middleware::ErrorHandler do
  let(:app) { double('app') }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }

  describe '#call' do
    context 'when request succeeds with 2xx' do
      let(:response) { double('response', status: 200, body: { 'success' => true }, env: { status: 200, body: { 'success' => true } }) }

      it 'passes through to the next middleware' do
        expect(app).to receive(:call).with(env).and_return(response)

        result = middleware.call(env)
        expect(result).to eq(response)
      end
    end

    context 'when response has 401 status' do
      let(:response) { double('response', status: 401, body: { 'error' => 'Invalid API key' }, env: {}) }

      it 'raises AuthenticationError with extracted message' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::AuthenticationError,
          /Invalid API key/
        )
      end
    end

    context 'when response has 401 status without error message' do
      let(:response) { double('response', status: 401, body: {}, env: {}) }

      it 'raises AuthenticationError with default message' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::AuthenticationError,
          /Authentication failed/
        )
      end
    end

    context 'when response has 4xx status' do
      let(:response) { double('response', status: 400, body: { 'error' => 'Bad request' }, env: {}) }

      it 'raises APIError with status code and message' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(VistarClient::APIError) do |error|
          expect(error.message).to include('Bad request')
          expect(error.status_code).to eq(400)
          expect(error.response_body).to eq({ 'error' => 'Bad request' })
        end
      end
    end

    context 'when response has 4xx status with message field' do
      let(:response) { double('response', status: 400, body: { 'message' => 'Validation failed' }, env: {}) }

      it 'extracts error from message field' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::APIError,
          /Validation failed/
        )
      end
    end

    context 'when response has 4xx status with error_description field' do
      let(:response) { double('response', status: 400, body: { 'error_description' => 'Missing required field' }, env: {}) }

      it 'extracts error from error_description field' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::APIError,
          /Missing required field/
        )
      end
    end

    context 'when response has 4xx status without error message' do
      let(:response) { double('response', status: 400, body: {}, env: {}) }

      it 'uses default error message with status code' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::APIError,
          /API request failed with status 400/
        )
      end
    end

    context 'when response has 4xx status with non-hash body' do
      let(:response) { double('response', status: 400, body: 'plain text error', env: {}) }

      it 'uses default error message' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(
          VistarClient::APIError,
          /API request failed with status 400/
        )
      end
    end

    context 'when response has 5xx status' do
      let(:response) { double('response', status: 500, body: { 'error' => 'Internal server error' }, env: {}) }

      it 'raises APIError with status code and message' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.to raise_error(VistarClient::APIError) do |error|
          expect(error.message).to include('Internal server error')
          expect(error.status_code).to eq(500)
          expect(error.response_body).to eq({ 'error' => 'Internal server error' })
        end
      end
    end

    context 'when response has 3xx redirect status' do
      let(:response) { double('response', status: 302, body: {}, env: {}) }

      it 'does not raise an error' do
        expect(app).to receive(:call).with(env).and_return(response)

        expect { middleware.call(env) }.not_to raise_error
      end
    end

    context 'when network errors occur' do
      it 'raises ConnectionError for TimeoutError' do
        allow(app).to receive(:call).and_raise(Faraday::TimeoutError, 'timeout')

        expect { middleware.call(env) }.to raise_error(
          VistarClient::ConnectionError,
          /Connection failed: timeout/
        )
      end

      it 'raises ConnectionError for ConnectionFailed' do
        allow(app).to receive(:call).and_raise(Faraday::ConnectionFailed, 'connection refused')

        expect { middleware.call(env) }.to raise_error(
          VistarClient::ConnectionError,
          /Connection failed: connection refused/
        )
      end

      it 'raises ConnectionError for other Faraday errors' do
        allow(app).to receive(:call).and_raise(Faraday::Error, 'network error')

        expect { middleware.call(env) }.to raise_error(
          VistarClient::ConnectionError,
          /Network error: network error/
        )
      end
    end
  end

  describe 'initialization' do
    it 'accepts optional configuration' do
      options = { custom: 'option' }
      middleware = described_class.new(app, options)

      expect(middleware).to be_a(described_class)
    end
  end
end
