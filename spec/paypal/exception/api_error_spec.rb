require 'spec_helper.rb'

describe Paypal::Exception::APIError do
  let(:error) { Paypal::Exception::APIError.new(params) }

  context 'when Hash is given' do
    let :params do
      {
        :VERSION=>"66.0",
        :TIMESTAMP=>"2011-03-03T06:33:51Z",
        :CORRELATIONID=>"758ebdc546b9c",
        :BUILD=>"1741654",
        :ACK=>"Failure",
        :L_SEVERITYCODE0=>"Error",
        :L_ERRORCODE0=>"10411",
        :L_LONGMESSAGE0=>"This Express Checkout session has expired.  Token value is no longer valid.",
        :L_SHORTMESSAGE0=>"This Express Checkout session has expired.",
        :L_SEVERITYCODE1=>"Error",
        :L_ERRORCODE1=>"2468",
        :L_LONGMESSAGE1=>"Sample of a long message for the second item.",
        :L_SHORTMESSAGE1=>"Second short message.",
      }
    end

    describe "#message" do
      it "aggregates short messages" do
        expect(error.message).to eq(
          "PayPal API Error: 'This Express Checkout session has expired.', 'Second short message.'"
        )
      end
    end

    describe '#subject' do
      subject { error.response }

      describe '#raw' do
        subject { super().raw }
        it { is_expected.to eq(params) }
      end
      Paypal::Exception::APIError::Response.attribute_mapping.each do |key, attribute|
        describe attribute do
          subject { super().send(attribute) }
          it { is_expected.to eq(params[key]) }
        end
      end

      describe '#details' do
        subject { error.response.details.first }
        Paypal::Exception::APIError::Response::Detail.attribute_mapping.each do |key, attribute|
          describe attribute do
            subject { super().send(attribute) }
            it { is_expected.to eq(params[:"L_#{key}0"]) }
          end
        end
      end
    end
  end

  context 'when unknown params given' do
    let :params do
      {
        :UNKNOWN => 'Unknown',
        :L_UNKNOWN0 => 'Unknown Detail'
      }
    end

    it 'should warn' do
      expect(Paypal.logger).to receive(:warn).with(
        "Ignored Parameter (Paypal::Exception::APIError::Response): UNKNOWN=Unknown"
      )
      expect(Paypal.logger).to receive(:warn).with(
        "Ignored Parameter (Paypal::Exception::APIError::Response::Detail): UNKNOWN=Unknown Detail"
      )
      error
    end
    describe '#response' do
      subject { error.response }

      describe '#raw' do
        subject { super().raw }
        it { is_expected.to eq(params) }
      end
    end

    describe '#message' do
      subject { super().message }
      it { is_expected.to eq("PayPal API Error") }
    end
  end

  context 'when refund failure params given' do
    let(:params) { { REFUNDSTATUS: 'None' } }
    describe 'error.response.refund_status' do
      subject { error.response.refund_status }
      it { should eq 'None' }
    end
  end

  context 'otherwise' do
    subject { error }
    let(:params) { 'Failure' }

    describe '#response' do
      subject { super().response }
      it { is_expected.to eq(params) }
    end

    describe '#message' do
      subject { super().message }
      it { is_expected.to eq("PayPal API Error") }
    end
  end
end
