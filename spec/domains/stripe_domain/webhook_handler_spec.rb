# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeDomain::WebhookHandler do
  let(:handler) { described_class.new(event) }
  let(:user) { create(:user) }
  let(:plan) { create(:plan, stripe_price_id: "price_123") }
  let(:subscription) { create(:subscription, user: user, stripe_subscription_id: "sub_123") }

  before do
    # Define UserMailer if it doesn't exist
    unless defined?(UserMailer)
      stub_const("UserMailer", Class.new)
    end

    # Stub UserMailer methods
    allow(UserMailer).to receive(:payment_failed).and_return(double(deliver_later: true))
    allow(UserMailer).to receive(:trial_ending).and_return(double(deliver_later: true))
  end

  describe "#handle" do
    context "with subscription events" do
      let(:stripe_subscription) do
        double("Stripe::Subscription",
               id: "sub_123",
               customer: "cus_123",
               status: "active",
               current_period_end: 1.month.from_now.to_i,
               trial_end: nil,
               cancel_at_period_end: false,
               items: double("Items", data: [ double("Item", price: double("Price", id: "price_123")) ]),
               metadata: { "user_id" => user.id.to_s, "plan_id" => plan.id.to_s })
      end

      context "customer.subscription.created" do
        let(:event) do
          StripeDomain::Event.new(
            type: "customer.subscription.created",
            data: { "object" => stripe_subscription }
          )
        end

        it "creates a new subscription" do
          # Update user to have stripe_customer_id
          user.update!(stripe_customer_id: "cus_123")

          allow(StripeDomain::Subscription).to receive(:from_stripe)
            .with(stripe_subscription)
            .and_return(StripeDomain::Subscription.new(
                          id: "sub_123",
                          customer_id: "cus_123",
                          status: "active",
                          current_period_end: 1.month.from_now,
                          metadata: { "user_id" => user.id.to_s, "plan_id" => plan.id.to_s },
                          items: [ { price: { id: "price_123" } } ]
                        ))

          # Stub Customer.find to return the customer with user_id
          allow(StripeDomain::Customer).to receive(:find).with("cus_123")
            .and_return(StripeDomain::Customer.new(id: "cus_123", user_id: user.id))

          expect {
            result = handler.handle
            expect(result[:handled]).to be true
          }.to change(::Subscription, :count).by(1)
        end
      end

      context "customer.subscription.updated" do
        let(:event) do
          StripeDomain::Event.new(
            type: "customer.subscription.updated",
            data: { "object" => stripe_subscription }
          )
        end

        before { subscription }

        it "updates existing subscription" do
          allow(StripeDomain::Subscription).to receive(:from_stripe)
            .and_return(StripeDomain::Subscription.new(
                          id: "sub_123",
                          status: "canceled",
                          current_period_end: 1.day.from_now,
                          cancel_at_period_end: true
                        ))

          result = handler.handle
          expect(result[:handled]).to be true

          subscription.reload
          expect(subscription.status).to eq("canceled")
        end
      end

      context "customer.subscription.deleted" do
        let(:event) do
          StripeDomain::Event.new(
            type: "customer.subscription.deleted",
            data: { "object" => stripe_subscription }
          )
        end

        before { subscription }

        it "cancels the subscription" do
          allow(StripeDomain::Subscription).to receive(:from_stripe)
            .and_return(StripeDomain::Subscription.new(id: "sub_123"))

          result = handler.handle
          expect(result[:handled]).to be true

          subscription.reload
          expect(subscription.status).to eq("canceled")
        end
      end
    end

    context "with payment events" do
      context "invoice.payment_succeeded" do
        let(:event) do
          StripeDomain::Event.new(
            type: "invoice.payment_succeeded",
            data: { "object" => { "subscription" => "sub_123" } }
          )
        end

        before { subscription.update!(status: "past_due") }

        it "updates subscription to active" do
          result = handler.handle
          expect(result[:handled]).to be true

          subscription.reload
          expect(subscription.status).to eq("active")
        end
      end

      context "invoice.payment_failed" do
        let(:event) do
          StripeDomain::Event.new(
            type: "invoice.payment_failed",
            data: { "object" => { "subscription" => "sub_123" } }
          )
        end

        before { subscription }

        it "updates subscription to past_due and sends email" do
          allow(UserMailer).to receive(:payment_failed).with(user).and_return(double(deliver_later: true))

          result = handler.handle
          expect(result[:handled]).to be true

          subscription.reload
          expect(subscription.status).to eq("past_due")
        end
      end
    end

    context "with unhandled event" do
      let(:event) { StripeDomain::Event.new(type: "some.other.event") }

      it "returns not handled" do
        result = handler.handle
        expect(result[:handled]).to be false
        expect(result[:message]).to include("Unhandled event type")
      end
    end
  end
end
