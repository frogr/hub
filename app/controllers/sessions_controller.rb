class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, except: :destroy

  def new
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)
    
    if user.nil?
      redirect_to new_session_path, alert: "User not found"
    elsif !user.passwordless_login_enabled?
      redirect_to new_user_session_path, alert: "Password login required for this account"
    else
      session = user.create_passwordless_session!
      UserMailer.magic_link(user, session).deliver_later
      redirect_to new_session_path, notice: "Magic link sent to your email"
    end
  end

  def show
    if session = PasswordlessSession.find_valid(params[:token])
      session.claim!
      sign_in(session.user)
      redirect_to after_sign_in_path_for(session.user), notice: "Successfully authenticated"
    else
      redirect_to new_session_path, alert: "Invalid or expired magic link"
    end
  end

  def destroy
    sign_out if user_signed_in?
    redirect_to new_session_path, notice: "Successfully signed out!"
  end

  private

  def redirect_if_authenticated
    redirect_to dashboard_index_path if user_signed_in?
  end
end
