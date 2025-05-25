class PricingController < ApplicationController
  def index
    @plans = Plan.order(:amount)
    @current_plan = current_user&.current_plan
    @subscription = current_user&.subscription
  end
end
