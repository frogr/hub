# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeDomain::Event do
  let(:stripe_event) do
    double("Stripe::Event",
           id: "evt_123",
           type: "customer.subscription.created",
           data: { "object" => { "id" => "sub_123" }, "previous_attributes" => {} },
           livemode: false,
           created: 1_234_567_890,
           request: double("Request", id: "req_123"))
  end

  describe ".from_stripe" do
    it "creates a domain event from Stripe event" do
      event = described_class.from_stripe(stripe_event)

      expect(event).to be_a(described_class)
      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("customer.subscription.created")
      expect(event.data).to eq("object" => { "id" => "sub_123" }, "previous_attributes" => {})
      expect(event.livemode).to be false
      expect(event.created_at).to eq(Time.at(1_234_567_890).utc)
      expect(event.request_id).to eq("req_123")
    end

    it "returns nil for nil input" do
      expect(described_class.from_stripe(nil)).to be_nil
    end
  end

  describe "#object" do
    it "returns the object from data" do
      event = described_class.new(data: { "object" => { "id" => "sub_123" } })
      expect(event.object).to eq("id" => "sub_123")
    end

    it "returns nil when no data" do
      event = described_class.new
      expect(event.object).to be_nil
    end
  end

  describe "#previous_attributes" do
    it "returns previous attributes from data" do
      event = described_class.new(
        data: { "previous_attributes" => { "status" => "trialing" } }
      )
      expect(event.previous_attributes).to eq("status" => "trialing")
    end
  end

  describe "event type checks" do
    it "#subscription? returns true for subscription events" do
      event = described_class.new(type: "customer.subscription.created")
      expect(event.subscription?).to be true
    end

    it "#payment? returns true for payment events" do
      event = described_class.new(type: "invoice.payment_succeeded")
      expect(event.payment?).to be true
    end

    it "#customer? returns true for customer events" do
      event = described_class.new(type: "customer.created")
      expect(event.customer?).to be true
    end

    it "#subscription_created? returns true for subscription created" do
      event = described_class.new(type: "customer.subscription.created")
      expect(event.subscription_created?).to be true
    end

    it "#subscription_updated? returns true for subscription updated" do
      event = described_class.new(type: "customer.subscription.updated")
      expect(event.subscription_updated?).to be true
    end

    it "#subscription_deleted? returns true for subscription deleted" do
      event = described_class.new(type: "customer.subscription.deleted")
      expect(event.subscription_deleted?).to be true
    end

    it "#payment_succeeded? returns true for payment succeeded" do
      event = described_class.new(type: "invoice.payment_succeeded")
      expect(event.payment_succeeded?).to be true
    end

    it "#payment_failed? returns true for payment failed" do
      event = described_class.new(type: "invoice.payment_failed")
      expect(event.payment_failed?).to be true
    end
  end

  describe ".construct_from" do
    let(:payload) { '{"id": "evt_123"}' }
    let(:sig_header) { "t=123,v1=abc" }
    let(:endpoint_secret) { "whsec_test" }

    it "constructs event from webhook payload" do
      expect(::Stripe::Webhook).to receive(:construct_event)
        .with(payload, sig_header, endpoint_secret)
        .and_return(stripe_event)

      event = described_class.construct_from(payload, sig_header, endpoint_secret)
      expect(event).to be_a(described_class)
      expect(event.id).to eq("evt_123")
    end
  end
end