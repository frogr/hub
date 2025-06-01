# frozen_string_literal: true

class CheckoutForm < BaseForm
  attribute :plan_id, :integer
  attribute :user_id, :integer
  attribute :stripe_session_id, :string
  attribute :success_url, :string
  attribute :cancel_url, :string

  validates :plan_id, presence: true
  validates :user_id, presence: true
  validates :success_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :cancel_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  def initialize(attributes = {})
    super
  end

  def user
    @user ||= User.find_by(id: user_id)
  end

  def plan
    @plan ||= Plan.find_by(id: plan_id)
  end

  def create_checkout_session
    return false unless valid?

    ensure_stripe_customer
    session = create_stripe_session

    if session
      @stripe_session = session
      self.stripe_session_id = session.id
      true
    else
      errors.add(:base, "Could not create checkout session")
      false
    end
  rescue Stripe::StripeError => e
    errors.add(:base, e.message)
    false
  end

  def checkout_url
    @stripe_session&.url
  end

  private

  def persist!
    create_checkout_session
  end

  def ensure_stripe_customer
    return if user.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      metadata: { user_id: user.id }
    )
    user.update!(stripe_customer_id: customer.id)
  end

  def create_stripe_session
    Stripe::Checkout::Session.create(
      customer: user.stripe_customer_id,
      payment_method_types: [ "card" ],
      line_items: [ {
        price: plan.stripe_price_id,
        quantity: 1
      } ],
      mode: "subscription",
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        user_id: user.id,
        plan_id: plan.id
      }
    )
  end
end
