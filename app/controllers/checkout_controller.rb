class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    @plan = Plan.find_by(id: params[:plan_id])
    redirect_to subscriptions_path, alert: "Invalid plan" unless @plan
  end

  def cancel
    redirect_to subscriptions_path, notice: "Checkout was cancelled."
  end
end
