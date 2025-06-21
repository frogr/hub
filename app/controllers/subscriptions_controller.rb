class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: [ :new, :create ]

  def index
    @plans = Plan.all.order(:amount)
    @current_subscription = current_user.subscription
    @subscriptions = current_user.subscriptions.includes(:plan)
  end

  def new
    redirect_to(subscriptions_path, alert: "Please select a plan") unless @plan
  end

  def create
    unless @plan
      redirect_to subscriptions_path, alert: "Please select a plan"
      return
    end
    
    session_url = current_user.create_checkout_session(
      plan: @plan,
      success_url: checkout_success_url(plan_id: @plan.id),
      cancel_url: checkout_cancel_url
    )

    redirect_to session_url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    redirect_to subscriptions_path, alert: e.message
  end

  def cancel
    subscription = current_user.subscription

    if subscription&.stripe_subscription_id?
      Stripe::Subscription.update(
        subscription.stripe_subscription_id,
        cancel_at_period_end: true
      )
      subscription.update!(cancel_at_period_end: true)
      redirect_to subscriptions_path, notice: "Your subscription will be cancelled at the end of the billing period."
    else
      redirect_to subscriptions_path, alert: "Unable to cancel subscription."
    end
  rescue Stripe::StripeError
    redirect_to subscriptions_path, alert: "Unable to cancel subscription."
  end

  private

  def set_plan
    @plan = Plan.find_by(id: params[:plan_id])
  end
end
