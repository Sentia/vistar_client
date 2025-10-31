# frozen_string_literal: true

require 'spec_helper'
require 'vistar_client/middleware/error_handler'

RSpec.describe VistarClient::Middleware::ErrorHandler do
  let(:app) { double('app') }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }

  describe '#call' do
    context 'when request succeeds' do
      it 'passes through to the next middleware' do
        expect(app).to receive(:call).with(env).and_return(double('response'))

        middleware.call(env)
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

  describe '#on_complete' do
    let(:env) { { status: status, body: body } }
    let(:body) { {} }

    context 'with 401 status' do
      let(:status) { 401 }

      it 'raises AuthenticationError' do
        expect { middleware.on_complete(env) }.to raise_error(
          VistarClient::AuthenticationError,
          /Authentication failed/
        )
      end

      context 'with error message in response' do
        let(:body) { { 'error' => 'Invalid API key' } }

        it 'includes the error message' do
          expect { middleware.on_complete(env) }.to raise_error(
            VistarClient::AuthenticationError,
            /Invalid API key/
          )
        end
      end
    end

    context 'with 4xx client errors' do
      let(:status) { 400 }
      let(:body) { { 'error' => 'Bad request' } }

      it 'raises APIError with status code' do
        expect { middleware.on_complete(env) }.to raise_error(VistarClient::APIError) do |error|
          expect(error.message).to include('Bad request')
          expect(error.status_code).to eq(400)
          expect(error.response_body).to eq(body)
        end
      end

      context 'with different error keys' do
        let(:body) { { 'message' => 'Validation failed' } }

        it 'extracts error from message field' do
          expect { middleware.on_complete(env) }.to raise_error(
            VistarClient::APIError,
            /Validation failed/
          )
        end
      end

      context 'with error_description key' do
        let(:body) { { 'error_description' => 'Missing required field' } }

        it 'extracts error from error_description field' do
          expect { middleware.on_complete(env) }.to raise_error(
            VistarClient::APIError,
            /Missing required field/
          )
        end
      end

      context 'without error message in body' do
        let(:body) { {} }

        it 'uses default error message with status code' do
          expect { middleware.on_complete(env) }.to raise_error(
            VistarClient::APIError,
            /API request failed with status 400/
          )
        end
      end

      context 'with non-hash body' do
        let(:body) { 'plain text error' }

        it 'uses default error message' do
          expect { middleware.on_complete(env) }.to raise_error(
            VistarClient::APIError,
            /API request failed with status 400/
          )
        end
      end
    end

    context 'with 5xx server errors' do
      let(:status) { 500 }
      let(:body) { { 'error' => 'Internal server error' } }

      it 'raises APIError with status code' do
        expect { middleware.on_complete(env) }.to raise_error(VistarClient::APIError) do |error|
          expect(error.message).to include('Internal server error')
          expect(error.status_code).to eq(500)
          expect(error.response_body).to eq(body)
        end
      end
    end

    context 'with 2xx success status' do
      let(:status) { 200 }

      it 'does not raise an error' do
        expect { middleware.on_complete(env) }.not_to raise_error
      end
    end

    context 'with 3xx redirect status' do
      let(:status) { 302 }

      it 'does not raise an error' do
        expect { middleware.on_complete(env) }.not_to raise_error
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
