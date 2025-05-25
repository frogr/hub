class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :update_subscription ]

  def index
    @users = User.includes(:subscription, subscription: :plan).order(created_at: :desc)
  end

  def show
  end

  def edit
    @plans = Plan.order(:amount)
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    else
      render :edit
    end
  end

  def update_subscription
    plan = Plan.find(params[:plan_id])

    if @user.subscription
      @user.subscription.update!(
        plan: plan,
        status: params[:status] || @user.subscription.status,
        trial_ends_at: params[:trial_ends_at].present? ? params[:trial_ends_at] : @user.subscription.trial_ends_at
      )
    else
      @user.create_subscription!(
        plan: plan,
        status: params[:status] || "active",
        trial_ends_at: params[:trial_ends_at].present? ? params[:trial_ends_at] : nil
      )
    end

    redirect_to admin_user_path(@user), notice: "Subscription updated successfully."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email)
  end
end
