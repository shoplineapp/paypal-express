require 'spec_helper.rb'

describe Paypal::NVP::Request do
  let :attributes do
    {
      :username => 'nov',
      :password => 'password',
      :signature => 'sig'
    }
  end

  let :instance do
    Paypal::NVP::Request.new attributes
  end

  describe '.new' do
    context 'when any required parameters are missing' do
      it 'should raise AttrRequired::AttrMissing' do
        attributes.keys.each do |missing_key|
          insufficient_attributes = attributes.reject do |key, value|
            key == missing_key
          end
          expect do
            Paypal::NVP::Request.new insufficient_attributes
          end.to raise_error AttrRequired::AttrMissing
        end
      end
    end

    context 'when all required parameters are given' do
      it 'should succeed' do
        expect do
          Paypal::NVP::Request.new attributes
        end.not_to raise_error
      end

      it 'should setup endpoint and version' do
        client = Paypal::NVP::Request.new attributes
        expect(client.class.endpoint).to eq(Paypal::NVP::Request::ENDPOINT[:production])
      end

      it 'should support sandbox mode' do
        sandbox_mode do
          client = Paypal::NVP::Request.new attributes
          expect(client.class.endpoint).to eq(Paypal::NVP::Request::ENDPOINT[:sandbox])
        end
      end
    end

    context 'when optional parameters are given' do
      let(:optional_attributes) do
        { :subject => 'user@example.com' }
      end

      it 'should setup subject' do
        client = Paypal::NVP::Request.new attributes.merge(optional_attributes)
        expect(client.subject).to eq('user@example.com')
      end
    end
  end

  describe '#common_params' do
    [
      [:username, :USER],
      [:password, :PWD],
      [:signature, :SIGNATURE],
      [:subject, :SUBJECT],
      [:version, :VERSION],
      [:version, :version]
    ].each do |method, param_key|
      it "should include :#{param_key}" do
        expect(instance.common_params).to include(param_key)
      end

      it "should set :#{param_key} to return of ##{method}" do
        expect(instance.common_params[param_key]).to eq(instance.send(method))
      end
    end
  end

  describe '#request' do
    it 'should POST to NPV endpoint' do
      expect do
        instance.request :RPCMethod
      end.to request_to Paypal::NVP::Request::ENDPOINT[:production], :post
    end

    context 'when got API error response' do
      before do
        fake_response 'SetExpressCheckout/failure'
      end

      it 'should raise Paypal::Exception::APIError' do
        expect do
          instance.request :SetExpressCheckout
        end.to raise_error(Paypal::Exception::APIError)
      end
    end

    context 'when API error response received from RefundTransaction' do
      before { fake_response 'RefundTransaction/failure' }

      it 'should handle all attributes while raising an API error' do
        expect(Paypal.logger).not_to receive(:warn)
        expect do
          instance.request :Refund, TRANSACTIONID: 'already-refunded'
        end.to raise_error(Paypal::Exception::APIError)
      end
    end

    context 'when got HTTP error response' do
      before do
        stub_request(:post, Paypal::NVP::Request::ENDPOINT[:production])
          .to_return(body: 'Invalid Request', status: 400)
      end

      it 'should raise Paypal::Exception::HttpError' do
        expect do
          instance.request :SetExpressCheckout
        end.to raise_error(Paypal::Exception::HttpError)
      end
    end
  end
end
