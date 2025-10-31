# frozen_string_literal: true

RSpec.describe VistarClient::Error do
  describe 'inheritance' do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end

    it 'can be rescued with StandardError' do
      expect do
        raise described_class, 'test error'
      end.to raise_error(StandardError)
    end
  end

  describe 'error message' do
    it 'accepts and stores a custom message' do
      error = described_class.new('custom message')
      expect(error.message).to eq('custom message')
    end
  end

  describe 'rescuing all gem errors' do
    it 'can rescue AuthenticationError' do
      expect do
        raise VistarClient::AuthenticationError, 'auth failed'
      rescue described_class => e
        expect(e).to be_a(VistarClient::AuthenticationError)
        expect(e.message).to eq('auth failed')
      end.not_to raise_error
    end

    it 'can rescue APIError' do
      expect do
        raise VistarClient::APIError, 'api failed'
      rescue described_class => e
        expect(e).to be_a(VistarClient::APIError)
        expect(e.message).to eq('api failed')
      end.not_to raise_error
    end

    it 'can rescue ConnectionError' do
      expect do
        raise VistarClient::ConnectionError, 'connection failed'
      rescue described_class => e
        expect(e).to be_a(VistarClient::ConnectionError)
        expect(e.message).to eq('connection failed')
      end.not_to raise_error
    end
  end
end

RSpec.describe VistarClient::AuthenticationError do
  describe 'inheritance' do
    it 'inherits from VistarClient::Error' do
      expect(described_class).to be < VistarClient::Error
    end
  end

  describe 'error message' do
    it 'accepts and stores a custom message' do
      error = described_class.new('unauthorized')
      expect(error.message).to eq('unauthorized')
    end
  end

  describe 'usage' do
    it 'can be raised and rescued' do
      expect do
        raise described_class, 'Invalid API key'
      end.to raise_error(described_class, 'Invalid API key')
    end
  end
end

RSpec.describe VistarClient::APIError do
  describe 'inheritance' do
    it 'inherits from VistarClient::Error' do
      expect(described_class).to be < VistarClient::Error
    end
  end

  describe '#initialize' do
    context 'with only message' do
      let(:error) { described_class.new('bad request') }

      it 'stores the message' do
        expect(error.message).to eq('bad request')
      end

      it 'has nil status_code' do
        expect(error.status_code).to be_nil
      end

      it 'has nil response_body' do
        expect(error.response_body).to be_nil
      end
    end

    context 'with message and status_code' do
      let(:error) { described_class.new('bad request', status_code: 400) }

      it 'stores the message' do
        expect(error.message).to eq('bad request')
      end

      it 'stores the status_code' do
        expect(error.status_code).to eq(400)
      end

      it 'has nil response_body' do
        expect(error.response_body).to be_nil
      end
    end

    context 'with all parameters' do
      let(:response_body) { { 'error' => 'Invalid request', 'details' => 'Missing required field' } }
      let(:error) do
        described_class.new(
          'API returned 400',
          status_code: 400,
          response_body: response_body
        )
      end

      it 'stores the message' do
        expect(error.message).to eq('API returned 400')
      end

      it 'stores the status_code' do
        expect(error.status_code).to eq(400)
      end

      it 'stores the response_body' do
        expect(error.response_body).to eq(response_body)
      end
    end

    context 'with string response_body' do
      let(:error) do
        described_class.new(
          'Server error',
          status_code: 500,
          response_body: 'Internal Server Error'
        )
      end

      it 'stores string response_body' do
        expect(error.response_body).to eq('Internal Server Error')
      end
    end
  end

  describe 'attr_readers' do
    let(:error) do
      described_class.new(
        'test error',
        status_code: 404,
        response_body: { 'error' => 'not found' }
      )
    end

    it 'provides read access to status_code' do
      expect(error.status_code).to eq(404)
    end

    it 'provides read access to response_body' do
      expect(error.response_body).to eq({ 'error' => 'not found' })
    end

    it 'does not allow writing to status_code' do
      expect { error.status_code = 500 }.to raise_error(NoMethodError)
    end

    it 'does not allow writing to response_body' do
      expect { error.response_body = {} }.to raise_error(NoMethodError)
    end
  end

  describe 'usage' do
    it 'can be raised and rescued' do
      expect do
        raise described_class.new('bad request', status_code: 400)
      end.to raise_error(described_class)
    end

    it 'includes status_code in raised error' do
      error = nil
      expect do
        raise described_class.new('bad request', status_code: 400)
      end.to raise_error(described_class) { |e| error = e }

      expect(error.message).to eq('bad request')
      expect(error.status_code).to eq(400)
    end

    it 'can be rescued as VistarClient::Error' do
      expect do
        raise described_class.new('api error', status_code: 500)
      rescue VistarClient::Error => e
        expect(e).to be_a(described_class)
        expect(e.status_code).to eq(500)
      end.not_to raise_error
    end
  end
end

RSpec.describe VistarClient::ConnectionError do
  describe 'inheritance' do
    it 'inherits from VistarClient::Error' do
      expect(described_class).to be < VistarClient::Error
    end
  end

  describe 'error message' do
    it 'accepts and stores a custom message' do
      error = described_class.new('connection timeout')
      expect(error.message).to eq('connection timeout')
    end
  end

  describe 'usage' do
    it 'can be raised and rescued' do
      expect do
        raise described_class, 'Network unreachable'
      end.to raise_error(described_class, 'Network unreachable')
    end
  end
end
