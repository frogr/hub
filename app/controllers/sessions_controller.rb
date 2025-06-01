class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create, :show ]

  def new
    @form = LoginForm.new
  end

  def create
    @form = LoginForm.new(email: params[:email])

    # First check if we should prevent login for specific cases
    user = User.find_by(email: params[:email])

    # Special handling for existing users with passwordless login disabled
    if user && !user.passwordless_login_enabled?
      redirect_to new_user_session_path, alert: "Password login required for this account"
      return
    end

    # Prevent auto-creation of users by checking before request_login
    if user.nil?
      redirect_to new_session_path, alert: "User not found"
      return
    end

    if @form.request_login
      UserMailer.magic_link(@form.user.to_model, @form.session.to_model).deliver_later
      redirect_to new_session_path, notice: "Magic link sent to your email"
    else
      flash.now[:alert] = @form.errors.full_messages.first
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authenticator = Auth::Authenticator.new
    result = authenticator.authenticate(token: params[:token])

    if result.success?
      sign_in(result.data[:user].to_model)
      redirect_to after_sign_in_path_for(result.data[:user].to_model), notice: "Successfully authenticated"
    else
      redirect_to new_session_path, alert: error_message_for(result.error)
    end
  end

  def destroy
    if user_signed_in?
      authenticator = Auth::Authenticator.new
      authenticator.sign_out(user_id: current_user.id)
      sign_out(current_user)
      redirect_to new_session_path, notice: "Successfully signed out!"
    else
      redirect_to new_session_path
    end
  end

  private

  def error_message_for(error)
    case error
    when :invalid_token
      "Invalid or expired magic link"
    when :expired_token
      "Invalid or expired magic link"
    when :already_claimed
      "This magic link has already been used"
    when :user_not_found
      "User not found"
    else
      "An error occurred. Please try again."
    end
  end

  def redirect_if_authenticated
    redirect_to dashboard_index_path if user_signed_in?
  end
end
