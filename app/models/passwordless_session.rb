class PasswordlessSession < ApplicationRecord
  belongs_to :authenticatable, polymorphic: true

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def user
    authenticatable if authenticatable_type == "User"
  end

  scope :available, -> { where(claimed_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :claimed, -> { where.not(claimed_at: nil) }

  before_validation :generate_token, on: :create


  def claim!
    update!(claimed_at: Time.current)
  end

  def claimed?
    claimed_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def available?
    !claimed? && !expired?
  end

  def expires_in
    return 0 if expired?

    ((expires_at - Time.current) / 1.hour).round(2)
  end


  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
