module StripeWebhookTestHelper
  class WebhookSimulator
    attr_reader :webhook_secret

    def initialize(webhook_secret: "test_webhook_secret")
      @webhook_secret = webhook_secret
    end

    # Simulates a Stripe webhook request with proper signature
    def simulate_event(event_type, event_data = {})
      event = build_event(event_type, event_data)
      payload = event.to_json
      signature = generate_signature(payload)

      {
        payload: payload,
        signature: signature,
        event: event
      }
    end

    # Generates valid Stripe signature header
    def generate_signature(payload, timestamp = Time.now.to_i)
      signed_payload = "#{timestamp}.#{payload}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, signed_payload)
      "t=#{timestamp},v1=#{signature}"
    end

    private

    def build_event(event_type, custom_data)
      base_event = {
        id: "evt_test_#{SecureRandom.hex(8)}",
        object: "event",
        api_version: "2023-10-16",
        created: Time.now.to_i,
        type: event_type,
        livemode: false,
        data: {
          object: default_event_data_for(event_type).merge(custom_data)
        }
      }

      Stripe::Event.construct_from(base_event)
    end

    def default_event_data_for(event_type)
      case event_type
      when "checkout.session.completed"
        {
          id: "cs_test_#{SecureRandom.hex(8)}",
          object: "checkout.session",
          mode: "subscription",
          subscription: "sub_test_#{SecureRandom.hex(8)}",
          customer: "cus_test_#{SecureRandom.hex(8)}",
          metadata: {},
          success_url: "https://example.com/success",
          cancel_url: "https://example.com/cancel"
        }
      when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
        {
          id: "sub_test_#{SecureRandom.hex(8)}",
          object: "subscription",
          customer: "cus_test_#{SecureRandom.hex(8)}",
          status: "active",
          current_period_end: 30.days.from_now.to_i,
          current_period_start: Time.now.to_i,
          cancel_at_period_end: false,
          items: {
            object: "list",
            data: [ {
              id: "si_test_#{SecureRandom.hex(8)}",
              price: {
                id: "price_test_#{SecureRandom.hex(8)}",
                product: "prod_test_#{SecureRandom.hex(8)}"
              }
            } ]
          }
        }
      when "invoice.payment_failed", "invoice.payment_succeeded"
        {
          id: "in_test_#{SecureRandom.hex(8)}",
          object: "invoice",
          subscription: "sub_test_#{SecureRandom.hex(8)}",
          customer: "cus_test_#{SecureRandom.hex(8)}",
          amount_paid: 0,
          amount_due: 999,
          currency: "usd",
          status: event_type.include?("failed") ? "open" : "paid"
        }
      when "payment_intent.succeeded", "payment_intent.payment_failed"
        {
          id: "pi_test_#{SecureRandom.hex(8)}",
          object: "payment_intent",
          amount: 999,
          currency: "usd",
          customer: "cus_test_#{SecureRandom.hex(8)}",
          status: event_type.include?("succeeded") ? "succeeded" : "requires_payment_method"
        }
      else
        {
          id: "obj_test_#{SecureRandom.hex(8)}",
          object: "unknown"
        }
      end
    end
  end

  # Rails console helper for testing webhooks locally
  class LocalWebhookTester
    def self.send_test_webhook(event_type, custom_data = {})
      simulator = WebhookSimulator.new(webhook_secret: Rails.configuration.stripe[:webhook_secret])
      webhook_data = simulator.simulate_event(event_type, custom_data)

      uri = URI("http://localhost:3000/webhooks/stripe")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Stripe-Signature"] = webhook_data[:signature]
      request.body = webhook_data[:payload]

      response = http.request(request)

      puts "Webhook sent!"
      puts "Response: #{response.code} - #{response.body}"
      response
    rescue => e
      puts "Error sending webhook: #{e.message}"
    end

    # Convenience methods for common events
    def self.test_checkout_completed(user_id:, plan_id:, subscription_id: nil)
      send_test_webhook("checkout.session.completed", {
        mode: "subscription",
        subscription: subscription_id || "sub_test_#{SecureRandom.hex(8)}",
        metadata: {
          user_id: user_id.to_s,
          plan_id: plan_id.to_s
        }
      })
    end

    def self.test_subscription_updated(stripe_subscription_id:, status: "active", cancel_at_period_end: false)
      send_test_webhook("customer.subscription.updated", {
        id: stripe_subscription_id,
        status: status,
        cancel_at_period_end: cancel_at_period_end,
        current_period_end: 30.days.from_now.to_i
      })
    end

    def self.test_subscription_deleted(stripe_subscription_id:)
      send_test_webhook("customer.subscription.deleted", {
        id: stripe_subscription_id
      })
    end

    def self.test_payment_failed(stripe_subscription_id:)
      send_test_webhook("invoice.payment_failed", {
        subscription: stripe_subscription_id
      })
    end
  end
end
