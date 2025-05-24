class PasswordlessSession < ApplicationRecord
  belongs_to :authenticatable, polymorphic: true
  
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  scope :available, -> { where(claimed_at: nil).where('expires_at > ?', Time.current) }
  
  before_validation :generate_token, on: :create
  
  private
  
  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
