require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:plan) }
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }
    
    it 'validates uniqueness of stripe_subscription_id' do
      subscription = create(:subscription, stripe_subscription_id: 'sub_123')
      duplicate_subscription = build(:subscription, stripe_subscription_id: 'sub_123')
      expect(duplicate_subscription).not_to be_valid
      expect(duplicate_subscription.errors[:stripe_subscription_id]).to include('has already been taken')
    end

    it 'allows nil stripe_subscription_id' do
      subscription = build(:subscription, stripe_subscription_id: nil)
      expect(subscription).to be_valid
    end
  end

  describe 'enums' do
    it 'defines status enum with correct values' do
      expect(Subscription.statuses).to eq({
        'trialing' => 'trialing',
        'active' => 'active',
        'canceled' => 'canceled',
        'past_due' => 'past_due',
        'unpaid' => 'unpaid',
        'incomplete' => 'incomplete'
      })
    end

    it 'provides status query methods' do
      subscription = build(:subscription, status: 'active')
      expect(subscription.active?).to be true
      expect(subscription.canceled?).to be false
    end
  end

  describe 'scopes' do
    describe '.active_or_trialing' do
      it 'returns active subscriptions' do
        active = create(:subscription, status: 'active')
        canceled = create(:subscription, :canceled)
        
        expect(Subscription.active_or_trialing).to include(active)
        expect(Subscription.active_or_trialing).not_to include(canceled)
      end

      it 'returns trialing subscriptions' do
        trialing = create(:subscription, :trialing)
        past_due = create(:subscription, :past_due)
        
        expect(Subscription.active_or_trialing).to include(trialing)
        expect(Subscription.active_or_trialing).not_to include(past_due)
      end

      it 'returns both active and trialing subscriptions' do
        active = create(:subscription, status: 'active')
        trialing = create(:subscription, :trialing)
        canceled = create(:subscription, :canceled)
        
        results = Subscription.active_or_trialing
        expect(results).to include(active, trialing)
        expect(results).not_to include(canceled)
      end
    end
  end

  describe '#active_or_trialing?' do
    it 'returns true for active subscriptions' do
      subscription = build(:subscription, status: 'active')
      expect(subscription.active_or_trialing?).to be true
    end

    it 'returns true for trialing subscriptions' do
      subscription = build(:subscription, :trialing)
      expect(subscription.active_or_trialing?).to be true
    end

    it 'returns false for canceled subscriptions' do
      subscription = build(:subscription, :canceled)
      expect(subscription.active_or_trialing?).to be false
    end

    it 'returns false for past_due subscriptions' do
      subscription = build(:subscription, :past_due)
      expect(subscription.active_or_trialing?).to be false
    end
  end

  describe '#cancelled?' do
    it 'returns true when status is canceled' do
      subscription = build(:subscription, :canceled)
      expect(subscription.cancelled?).to be true
    end

    it 'returns true when cancel_at_period_end is true' do
      subscription = build(:subscription, status: 'active', cancel_at_period_end: true)
      expect(subscription.cancelled?).to be true
    end

    it 'returns false when active and not set to cancel' do
      subscription = build(:subscription, status: 'active', cancel_at_period_end: false)
      expect(subscription.cancelled?).to be false
    end

    it 'returns true when both canceled and set to cancel at period end' do
      subscription = build(:subscription, status: 'canceled', cancel_at_period_end: true)
      expect(subscription.cancelled?).to be true
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:subscription)).to be_valid
    end

    it 'has a valid trialing trait' do
      subscription = build(:subscription, :trialing)
      expect(subscription).to be_valid
      expect(subscription.trialing?).to be true
      expect(subscription.current_period_end).to be_between(13.days.from_now, 15.days.from_now)
    end

    it 'has a valid canceled trait' do
      subscription = build(:subscription, :canceled)
      expect(subscription).to be_valid
      expect(subscription.canceled?).to be true
      expect(subscription.cancel_at_period_end).to be true
    end

    it 'has a valid past_due trait' do
      subscription = build(:subscription, :past_due)
      expect(subscription).to be_valid
      expect(subscription.past_due?).to be true
    end

    it 'has a valid unpaid trait' do
      subscription = build(:subscription, :unpaid)
      expect(subscription).to be_valid
      expect(subscription.unpaid?).to be true
    end

    it 'has a valid incomplete trait' do
      subscription = build(:subscription, :incomplete)
      expect(subscription).to be_valid
      expect(subscription.incomplete?).to be true
    end

    it 'has a valid with_stripe_ids trait' do
      subscription = build(:subscription, :with_stripe_ids)
      expect(subscription).to be_valid
      expect(subscription.stripe_subscription_id).to match(/^sub_test_\d+$/)
      expect(subscription.stripe_customer_id).to match(/^cus_test_\d+$/)
    end
  end
end