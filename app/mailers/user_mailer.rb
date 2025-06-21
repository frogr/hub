class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.magic_link.subject
  #
  def magic_link(user, session)
    @user = user
    @session = session
    @magic_link_url = sign_in_url(token: @session.token)

    mail(
      to: @user.email,
      subject: "Sign in to your account"
    )
  end

  def payment_failed(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Payment failed for your subscription"
    )
  end

  def trial_ending(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Your trial is ending soon"
    )
  end
end
