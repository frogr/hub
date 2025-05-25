class StripeCustomerService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def find_or_create
    return existing_customer if existing_customer.present?
    create_customer
  end

  def update
    return nil unless user.stripe_customer_id.present?

    Stripe::Customer.update(
      user.stripe_customer_id,
      customer_attributes
    )
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Failed to update Stripe customer: #{e.message}"
    nil
  end

  def sync_from_stripe
    return nil unless user.stripe_customer_id.present?

    customer = retrieve_customer
    return nil unless customer

    user.update!(email: customer.email) if customer.email != user.email
    customer
  end

  private

  def existing_customer
    return nil unless user.stripe_customer_id.present?
    @existing_customer ||= retrieve_customer
  end

  def retrieve_customer
    Stripe::Customer.retrieve(user.stripe_customer_id)
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Failed to retrieve Stripe customer: #{e.message}"
    nil
  end

  def create_customer
    customer = Stripe::Customer.create(customer_attributes)
    user.update!(stripe_customer_id: customer.id)
    customer
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create Stripe customer: #{e.message}"
    nil
  end

  def customer_attributes
    {
      email: user.email,
      metadata: {
        user_id: user.id,
        environment: Rails.env
      }
    }
  end
end
