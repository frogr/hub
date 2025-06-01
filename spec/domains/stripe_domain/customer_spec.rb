# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeDomain::Customer do
  let(:stripe_customer) do
    double("Stripe::Customer",
           id: "cus_123",
           email: "test@example.com",
           name: "Test User",
           description: "Test customer",
           metadata: { "user_id" => "1" },
           created: 1_234_567_890)
  end

  describe ".from_stripe" do
    it "creates a domain customer from Stripe customer" do
      customer = described_class.from_stripe(stripe_customer)

      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("cus_123")
      expect(customer.email).to eq("test@example.com")
      expect(customer.name).to eq("Test User")
      expect(customer.description).to eq("Test customer")
      expect(customer.metadata).to eq("user_id" => "1")
      expect(customer.created_at).to eq(Time.at(1_234_567_890).utc)
    end

    it "returns nil for nil input" do
      expect(described_class.from_stripe(nil)).to be_nil
    end
  end

  describe "#user_id" do
    it "returns user_id from metadata as integer" do
      customer = described_class.new(metadata: { "user_id" => "123" })
      expect(customer.user_id).to eq(123)
    end

    it "returns nil when user_id not in metadata" do
      customer = described_class.new(metadata: {})
      expect(customer.user_id).to be_nil
    end
  end

  describe "#to_stripe" do
    it "retrieves the Stripe customer object" do
      customer = described_class.new(id: "cus_123")
      expect(::Stripe::Customer).to receive(:retrieve).with("cus_123")
      customer.to_stripe
    end

    it "returns nil when id is not present" do
      customer = described_class.new
      expect(customer.to_stripe).to be_nil
    end
  end

  describe ".find" do
    it "finds and returns a domain customer" do
      expect(::Stripe::Customer).to receive(:retrieve)
        .with("cus_123")
        .and_return(stripe_customer)

      customer = described_class.find("cus_123")
      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("cus_123")
    end

    it "returns nil when customer not found" do
      expect(::Stripe::Customer).to receive(:retrieve)
        .and_raise(::Stripe::InvalidRequestError.new("Not found", nil))

      expect(described_class.find("cus_123")).to be_nil
    end
  end

  describe ".find_or_create_for_user" do
    let(:user) { double("User", id: 1, email: "user@example.com", stripe_customer_id: nil) }

    context "when user has stripe_customer_id" do
      before do
        allow(user).to receive(:stripe_customer_id).and_return("cus_existing")
      end

      it "retrieves existing customer" do
        expect(::Stripe::Customer).to receive(:retrieve)
          .with("cus_existing")
          .and_return(stripe_customer)

        customer = described_class.find_or_create_for_user(user)
        expect(customer.id).to eq("cus_123")
      end
    end

    context "when user doesn't have stripe_customer_id" do
      it "creates new customer and updates user" do
        expect(::Stripe::Customer).to receive(:create)
          .with(email: "user@example.com", metadata: { user_id: 1 })
          .and_return(stripe_customer)

        expect(user).to receive(:update!).with(stripe_customer_id: "cus_123")

        customer = described_class.find_or_create_for_user(user)
        expect(customer.id).to eq("cus_123")
      end
    end
  end

  describe ".update" do
    it "updates and returns domain customer" do
      expect(::Stripe::Customer).to receive(:update)
        .with("cus_123", { email: "new@example.com" })
        .and_return(stripe_customer)

      customer = described_class.update("cus_123", email: "new@example.com")
      expect(customer).to be_a(described_class)
    end
  end
end
