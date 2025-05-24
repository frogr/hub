class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :passwordless_sessions, as: :authenticatable, dependent: :destroy

  def passwordless_with(user_agent:, remote_addr:)
    passwordless_sessions.create!(
      user_agent: user_agent,
      remote_addr: remote_addr,
      expires_at: 1.hour.from_now
    )
  end
end
