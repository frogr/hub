namespace :stripe do
  namespace :webhooks do
    desc "Test a Stripe webhook locally"
    task :test, [ :event_type ] => :environment do |t, args|
      require_relative "../stripe_webhook_test_helper"
      include StripeWebhookTestHelper

      event_type = args[:event_type] || "checkout.session.completed"

      puts "Sending test webhook: #{event_type}"

      case event_type
      when "checkout.session.completed"
        # Create a test user and plan if needed
        user = User.first || User.create!(email: "test@example.com", name: "Test User")
        plan = Plan.first || Plan.create!(name: "Test Plan", price_cents: 999, stripe_price_id: "price_test")

        LocalWebhookTester.test_checkout_completed(user_id: user.id, plan_id: plan.id)
      when "customer.subscription.updated"
        subscription = Subscription.first
        if subscription
          LocalWebhookTester.test_subscription_updated(
            stripe_subscription_id: subscription.stripe_subscription_id,
            status: "active"
          )
        else
          puts "No subscription found. Create one first with checkout.session.completed event."
        end
      when "customer.subscription.deleted"
        subscription = Subscription.first
        if subscription
          LocalWebhookTester.test_subscription_deleted(
            stripe_subscription_id: subscription.stripe_subscription_id
          )
        else
          puts "No subscription found. Create one first with checkout.session.completed event."
        end
      when "invoice.payment_failed"
        subscription = Subscription.first
        if subscription
          LocalWebhookTester.test_payment_failed(
            stripe_subscription_id: subscription.stripe_subscription_id
          )
        else
          puts "No subscription found. Create one first with checkout.session.completed event."
        end
      else
        LocalWebhookTester.send_test_webhook(event_type)
      end
    end

    desc "List available webhook event types for testing"
    task list: :environment do
      puts "Available webhook event types for testing:"
      puts "- checkout.session.completed"
      puts "- customer.subscription.updated"
      puts "- customer.subscription.deleted"
      puts "- invoice.payment_failed"
      puts ""
      puts "Usage: rails stripe:webhooks:test[event_type]"
      puts "Example: rails stripe:webhooks:test[checkout.session.completed]"
    end

    desc "Simulate a complete subscription lifecycle"
    task lifecycle: :environment do |t, args|
      require_relative "../stripe_webhook_test_helper"
      include StripeWebhookTestHelper

      user = User.first || User.create!(email: "test@example.com", name: "Test User")
      plan = Plan.first || Plan.create!(name: "Test Plan", price_cents: 999, stripe_price_id: "price_test")
      subscription_id = "sub_test_#{SecureRandom.hex(8)}"

      puts "Simulating subscription lifecycle for user #{user.email}..."

      puts "\n1. Checkout completed..."
      LocalWebhookTester.test_checkout_completed(
        user_id: user.id,
        plan_id: plan.id,
        subscription_id: subscription_id
      )
      sleep 1

      puts "\n2. Subscription updated (past_due)..."
      LocalWebhookTester.test_subscription_updated(
        stripe_subscription_id: subscription_id,
        status: "past_due"
      )
      sleep 1

      puts "\n3. Payment failed..."
      LocalWebhookTester.test_payment_failed(
        stripe_subscription_id: subscription_id
      )
      sleep 1

      puts "\n4. Subscription canceled..."
      LocalWebhookTester.test_subscription_deleted(
        stripe_subscription_id: subscription_id
      )

      puts "\nLifecycle simulation complete!"
    end
  end
end
