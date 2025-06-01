# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeDomain::Subscription do
  let(:stripe_subscription) do
    double("Stripe::Subscription",
           id: "sub_123",
           customer: "cus_123",
           status: "active",
           current_period_start: 1_234_567_890,
           current_period_end: 1_234_654_290,
           cancel_at_period_end: false,
           canceled_at: nil,
           trial_start: nil,
           trial_end: nil,
           items: double("Items", data: [stripe_item]),
           metadata: { "user_id" => "1", "plan_id" => "2" },
           created: 1_234_567_890)
  end

  let(:stripe_item) do
    double("SubscriptionItem",
           id: "si_123",
           price: double("Price",
                         id: "price_123",
                         product: "prod_123",
                         unit_amount: 1999,
                         currency: "usd",
                         recurring: { interval: "month" }),
           quantity: 1)
  end

  describe ".from_stripe" do
    it "creates a domain subscription from Stripe subscription" do
      subscription = described_class.from_stripe(stripe_subscription)

      expect(subscription).to be_a(described_class)
      expect(subscription.id).to eq("sub_123")
      expect(subscription.customer_id).to eq("cus_123")
      expect(subscription.status).to eq("active")
      expect(subscription.current_period_start).to eq(Time.at(1_234_567_890).utc)
      expect(subscription.current_period_end).to eq(Time.at(1_234_654_290).utc)
      expect(subscription.cancel_at_period_end).to be false
      expect(subscription.metadata).to eq("user_id" => "1", "plan_id" => "2")
    end

    it "returns nil for nil input" do
      expect(described_class.from_stripe(nil)).to be_nil
    end
  end

  describe "status methods" do
    it "#active? returns true for active status" do
      subscription = described_class.new(status: "active")
      expect(subscription.active?).to be true
    end

    it "#trialing? returns true for trialing status" do
      subscription = described_class.new(status: "trialing")
      expect(subscription.trialing?).to be true
    end

    it "#canceled? returns true for canceled status" do
      subscription = described_class.new(status: "canceled")
      expect(subscription.canceled?).to be true
    end

    it "#canceled? returns true when cancel_at_period_end is true" do
      subscription = described_class.new(status: "active", cancel_at_period_end: true)
      expect(subscription.canceled?).to be true
    end

    it "#past_due? returns true for past_due status" do
      subscription = described_class.new(status: "past_due")
      expect(subscription.past_due?).to be true
    end
  end

  describe "#price_id" do
    it "returns price id from first item" do
      subscription = described_class.new(
        items: [{ price: { id: "price_123" } }]
      )
      expect(subscription.price_id).to eq("price_123")
    end

    it "returns nil when no items" do
      subscription = described_class.new(items: [])
      expect(subscription.price_id).to be_nil
    end
  end

  describe "#user_id and #plan_id" do
    it "returns ids from metadata as integers" do
      subscription = described_class.new(
        metadata: { "user_id" => "123", "plan_id" => "456" }
      )
      expect(subscription.user_id).to eq(123)
      expect(subscription.plan_id).to eq(456)
    end
  end

  describe ".find" do
    it "finds and returns a domain subscription" do
      expect(::Stripe::Subscription).to receive(:retrieve)
        .with("sub_123")
        .and_return(stripe_subscription)

      subscription = described_class.find("sub_123")
      expect(subscription).to be_a(described_class)
      expect(subscription.id).to eq("sub_123")
    end

    it "returns nil when not found" do
      expect(::Stripe::Subscription).to receive(:retrieve)
        .and_raise(::Stripe::InvalidRequestError.new("Not found", nil))

      expect(described_class.find("sub_123")).to be_nil
    end
  end

  describe ".create" do
    it "creates a new subscription" do
      expect(::Stripe::Subscription).to receive(:create)
        .with(
          customer: "cus_123",
          items: [{ price: "price_123" }],
          metadata: { user_id: 1 },
          trial_period_days: 14
        )
        .and_return(stripe_subscription)

      subscription = described_class.create(
        customer_id: "cus_123",
        price_id: "price_123",
        metadata: { user_id: 1 },
        trial_period_days: 14
      )

      expect(subscription).to be_a(described_class)
      expect(subscription.id).to eq("sub_123")
    end
  end

  describe ".cancel" do
    it "cancels at period end" do
      expect(::Stripe::Subscription).to receive(:update)
        .with("sub_123", cancel_at_period_end: true)
        .and_return(stripe_subscription)

      subscription = described_class.cancel("sub_123")
      expect(subscription).to be_a(described_class)
    end
  end

  describe ".cancel_immediately" do
    it "cancels immediately" do
      expect(::Stripe::Subscription).to receive(:cancel)
        .with("sub_123")
        .and_return(stripe_subscription)

      subscription = described_class.cancel_immediately("sub_123")
      expect(subscription).to be_a(described_class)
    end
  end
end