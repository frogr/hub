class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.find_by(email: params[:email])

    if @user&.passwordless_login_enabled?
      session = @user.passwordless_with(
        user_agent: request.user_agent,
        remote_addr: request.remote_ip
      )
      UserMailer.magic_link(@user, session).deliver_now

      redirect_to new_session_path, notice: "Check your email for a magic link!"
    elsif @user
      redirect_to new_user_session_path, alert: "Please use password login for your account."
    else
      redirect_to new_session_path, alert: "User not found."
    end
  end

  def show
    session = PasswordlessSession.available.find_by(token: params[:token])

    if session
      session.update!(claimed_at: Time.current)
      sign_in(session.authenticatable)
      redirect_to root_path, notice: "Successfully signed in!"
    else
      redirect_to new_session_path, alert: "Invalid or expired magic link."
    end
  end
end
