# Stripe Webhook Testing Guide

## Overview

This application includes a comprehensive webhook testing framework that allows you to test Stripe webhooks locally without needing to expose your development server to the internet.

## Architecture

Following Sandi Metz OOP principles, the webhook handling is organized into:

1. **WebhooksController** - Thin controller that only handles HTTP concerns
2. **StripeSignatureVerificationService** - Handles webhook signature validation
3. **StripeWebhookService** - Orchestrates event processing
4. **Event Handlers** - Individual handler classes for each event type

## Local Testing Methods

### 1. Rake Tasks

Test individual webhook events:
```bash
# Test specific event
rails stripe:webhooks:test[checkout.session.completed]
rails stripe:webhooks:test[customer.subscription.updated]
rails stripe:webhooks:test[customer.subscription.deleted]
rails stripe:webhooks:test[invoice.payment_failed]

# List available events
rails stripe:webhooks:list

# Simulate complete subscription lifecycle
rails stripe:webhooks:lifecycle
```

### 2. Rails Console

Use the LocalWebhookTester for more control:

```ruby
# Load the helper
require 'stripe_webhook_test_helper'
include StripeWebhookTestHelper

# Test checkout completed
LocalWebhookTester.test_checkout_completed(
  user_id: User.first.id,
  plan_id: Plan.first.id
)

# Test subscription update
LocalWebhookTester.test_subscription_updated(
  stripe_subscription_id: "sub_123",
  status: "past_due",
  cancel_at_period_end: true
)

# Send custom webhook
LocalWebhookTester.send_test_webhook("customer.created", {
  id: "cus_test123",
  email: "test@example.com"
})
```

### 3. WebhookSimulator

For advanced testing scenarios:

```ruby
simulator = StripeWebhookTestHelper::WebhookSimulator.new
webhook_data = simulator.simulate_event("checkout.session.completed", {
  metadata: {
    user_id: "1",
    plan_id: "2"
  }
})

# webhook_data contains:
# - payload: JSON string
# - signature: Valid Stripe signature
# - event: Stripe::Event object
```

## Testing in RSpec

The test suite includes comprehensive coverage:

```ruby
# In request specs
require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  include StripeWebhookTestHelper
  
  let(:simulator) { WebhookSimulator.new }
  
  it 'handles checkout.session.completed' do
    user = create(:user)
    webhook_data = simulator.simulate_event("checkout.session.completed", {
      metadata: { user_id: user.id.to_s }
    })
    
    post webhooks_stripe_path,
         params: webhook_data[:payload],
         headers: { 'HTTP_STRIPE_SIGNATURE' => webhook_data[:signature] }
    
    expect(response).to have_http_status(:ok)
  end
end
```

## Adding New Event Handlers

1. Add handler class to `StripeWebhookService`:

```ruby
class NewEventHandler < BaseHandler
  def handle
    # Implementation
  end
end
```

2. Register in the `handler_for` method:

```ruby
def handler_for(event_type)
  case event_type
  when "new.event.type"
    NewEventHandler
  # ...
  end
end
```

3. Add test coverage:
   - Unit test in `spec/services/stripe_webhook_service_spec.rb`
   - Integration test in `spec/requests/webhooks_spec.rb`

## Security Considerations

- Webhook endpoint skips CSRF protection (required for external POSTs)
- Signature verification is mandatory and happens before any processing
- Failed signature verification returns 400 Bad Request
- All webhook processing errors are logged but return 200 OK (Stripe best practice)

## Environment Configuration

Set your webhook secret in credentials:

```yaml
stripe:
  webhook_secret: whsec_test_...
```

For local testing, the test helpers use a default test secret that can be overridden.