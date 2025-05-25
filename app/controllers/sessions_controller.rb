class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create, :show ]

  def new
    @user = User.new
  end

  def create
    result = authentication_service.authenticate_with_magic_link

    if result[:success]
      redirect_to new_session_path, notice: result[:message]
    else
      handle_authentication_failure(result[:message])
    end
  end

  def show
    result = authentication_service.authenticate_with_token(params[:token])

    if result[:success]
      sign_in(result[:user])
      redirect_to after_sign_in_path_for(result[:user]), notice: result[:message]
    else
      redirect_to new_session_path, alert: result[:message]
    end
  end

  def destroy
    if user_signed_in?
      sign_out(current_user)
      redirect_to new_session_path, notice: "Successfully signed out!"
    else
      redirect_to new_session_path
    end
  end

  private

  def authentication_service
    @authentication_service ||= AuthenticationService.new(
      email: params[:email],
      user_agent: request.user_agent,
      remote_addr: request.remote_ip
    )
  end

  def handle_authentication_failure(message)
    case message
    when "Password login required for this account"
      redirect_to new_user_session_path, alert: message
    else
      redirect_to new_session_path, alert: message
    end
  end

  def redirect_if_authenticated
    redirect_to dashboard_index_path if user_signed_in?
  end
end
