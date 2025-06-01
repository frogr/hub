class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: [ :new, :create ]

  def index
    @repository = SubscriptionRepository.new
    @plans = Plan.all.order(:amount)
    @current_subscription = @repository.active_or_trialing_for_user(current_user)
    @subscriptions = @repository.all_for_user(current_user)
  end

  def new
    redirect_to subscriptions_path, alert: "Please select a plan" unless @plan
    @form = CheckoutForm.new(
      plan_id: @plan.id,
      user_id: current_user.id,
      success_url: checkout_success_url(plan_id: @plan.id),
      cancel_url: checkout_cancel_url
    )
  end

  def create
    unless @plan
      redirect_to subscriptions_path, alert: "Please select a plan" and return
    end

    @form = CheckoutForm.new(
      plan_id: @plan.id,
      user_id: current_user.id,
      success_url: checkout_success_url(plan_id: @plan.id),
      cancel_url: checkout_cancel_url
    )

    if @form.save
      redirect_to @form.checkout_url, allow_other_host: true, status: :see_other
    else
      flash.now[:alert] = @form.errors.full_messages.first
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @repository = SubscriptionRepository.new
    subscription = @repository.active_for_user(current_user)

    if subscription && @repository.cancel(subscription)
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
