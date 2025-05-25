class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: [ :new, :create ]

  def index
    @plans = Plan.all.order(:amount)
    @current_subscription = current_user.subscription
  end

  def new
    redirect_to subscriptions_path, alert: "Please select a plan" unless @plan
  end

  def create
    unless @plan
      redirect_to subscriptions_path, alert: "Please select a plan" and return
    end

    service = SubscriptionService.new(current_user, @plan)

    session = service.create_checkout_session(
      success_url: checkout_success_url(plan_id: @plan.id),
      cancel_url: checkout_cancel_url
    )

    if session
      redirect_to session.url, allow_other_host: true, status: :see_other
    else
      redirect_to subscriptions_path, alert: "Unable to create checkout session. Please try again."
    end
  end

  def cancel
    service = SubscriptionService.new(current_user)

    if service.cancel_subscription
      redirect_to subscriptions_path, notice: "Your subscription will be cancelled at the end of the billing period."
    else
      redirect_to subscriptions_path, alert: "Unable to cancel subscription. Please try again."
    end
  end

  private

  def set_plan
    @plan = Plan.find_by(id: params[:plan_id])
  end
end
