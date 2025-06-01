class Webhook < ApplicationRecord
  def self.process_stripe!(payload:, signature:)
    event = Stripe::Webhook.construct_event(
      payload, 
      signature, 
      Rails.configuration.stripe[:webhook_secret]
    )
    
    case event.type
    when "checkout.session.completed"
      return unless event.data.object.mode == "subscription"
      
      user = User.find(event.data.object.metadata.user_id)
      user.process_checkout_completed(event.data.object.subscription)
      
    when "customer.subscription.updated"
      subscription = Subscription.find_by!(stripe_subscription_id: event.data.object.id)
      subscription.update!(
        status: event.data.object.status,
        current_period_end: Time.at(event.data.object.current_period_end),
        cancel_at_period_end: event.data.object.cancel_at_period_end
      )
      
    when "customer.subscription.deleted"
      Subscription.find_by!(stripe_subscription_id: event.data.object.id)
                 .update!(status: "canceled")
    end
    
    create!(event_type: event.type, event_id: event.id, processed_at: Time.current)
  end
end