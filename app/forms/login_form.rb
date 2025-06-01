# frozen_string_literal: true

class LoginForm < BaseForm
  attribute :email, :string

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(attributes = {})
    super
    @authenticator = Auth::Authenticator.new
  end

  def email=(value)
    super(value&.strip&.downcase)
  end

  def request_login
    return false unless valid?

    result = @authenticator.request_login(email: email)

    if result.success?
      @user = result.data[:user]
      @session = result.data[:session]
      true
    else
      errors.add(:base, error_message_for(result.error))
      false
    end
  end

  def user
    @user
  end

  def session
    @session
  end

  private

  def persist!
    request_login
  end

  def error_message_for(error)
    case error
    when :invalid_email
      "Invalid email address"
    when :session_creation_failed
      "Could not create login session. Please try again."
    else
      "An error occurred. Please try again."
    end
  end
end
