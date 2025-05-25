class AuthenticationService
  attr_reader :email, :user_agent, :remote_addr

  def initialize(email:, user_agent: nil, remote_addr: nil)
    @email = email
    @user_agent = user_agent
    @remote_addr = remote_addr
  end

  def authenticate_with_magic_link
    user = find_user
    return authentication_result(false, "User not found") unless user

    unless user.passwordless_login_enabled?
      return authentication_result(false, "Password login required for this account")
    end

    session = create_passwordless_session(user)
    send_magic_link(user, session)

    authentication_result(true, "Magic link sent to your email")
  end

  def authenticate_with_token(token)
    session = find_valid_session(token)
    return authentication_result(false, "Invalid or expired magic link") unless session

    session.claim!
    authentication_result(true, "Successfully authenticated", user: session.authenticatable)
  end

  private

  def find_user
    User.find_by(email: email)
  end

  def create_passwordless_session(user)
    user.passwordless_with(
      user_agent: user_agent,
      remote_addr: remote_addr
    )
  end

  def send_magic_link(user, session)
    UserMailer.magic_link(user, session).deliver_now
    log_magic_link_in_development(session)
  end

  def find_valid_session(token)
    PasswordlessSession.available.find_by(token: token)
  end

  def log_magic_link_in_development(session)
    return unless Rails.env.development?

    magic_link_url = Rails.application.routes.url_helpers.sign_in_url(
      token: session.token,
      host: "localhost:3000"
    )

    puts "\n" + "="*50
    puts "MAGIC LINK FOR DEBUG:"
    puts magic_link_url
    puts "="*50 + "\n"
  end

  def authentication_result(success, message, user: nil)
    {
      success: success,
      message: message,
      user: user
    }
  end
end
