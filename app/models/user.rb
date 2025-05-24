class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :passwordless_sessions, as: :authenticatable, dependent: :destroy

  def passwordless_with(session)
    passwordless_sessions.create!(
      user_agent: session[:user_agent],
      remote_addr: session[:remote_addr],
      expires_at: 1.hour.from_now
    )
  end
end
