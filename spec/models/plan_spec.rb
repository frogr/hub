require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'associations' do
    it { should have_many(:subscriptions) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:interval) }
    it { should validate_inclusion_of(:interval).in_array(%w[month year]) }
    
    it 'validates uniqueness of stripe_price_id' do
      plan = create(:plan, stripe_price_id: 'price_123')
      duplicate_plan = build(:plan, stripe_price_id: 'price_123')
      expect(duplicate_plan).not_to be_valid
      expect(duplicate_plan.errors[:stripe_price_id]).to include('has already been taken')
    end

    it 'allows nil stripe_price_id' do
      plan = build(:plan, stripe_price_id: nil)
      expect(plan).to be_valid
    end
  end

  describe 'serialization' do
    it 'serializes features as an array' do
      plan = create(:plan, features: ['Feature 1', 'Feature 2'])
      plan.reload
      expect(plan.features).to eq(['Feature 1', 'Feature 2'])
    end

    it 'handles empty features array' do
      plan = create(:plan, features: [])
      plan.reload
      expect(plan.features).to eq([])
    end
  end

  describe '#free?' do
    it 'returns true when amount is 0' do
      plan = build(:plan, :free)
      expect(plan.free?).to be true
    end

    it 'returns false when amount is greater than 0' do
      plan = build(:plan, amount: 1999)
      expect(plan.free?).to be false
    end
  end

  describe '#display_price' do
    context 'when plan is free' do
      it 'returns "Free"' do
        plan = build(:plan, :free)
        expect(plan.display_price).to eq('Free')
      end
    end

    context 'when plan has a price' do
      it 'formats monthly price correctly' do
        plan = build(:plan, amount: 1999, interval: 'month')
        expect(plan.display_price).to eq('$19.99/month')
      end

      it 'formats yearly price correctly' do
        plan = build(:plan, amount: 19999, interval: 'year')
        expect(plan.display_price).to eq('$199.99/year')
      end

      it 'handles decimal amounts correctly' do
        plan = build(:plan, amount: 999, interval: 'month')
        expect(plan.display_price).to eq('$9.99/month')
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:plan)).to be_valid
    end

    it 'has a valid free trait' do
      plan = build(:plan, :free)
      expect(plan).to be_valid
      expect(plan.free?).to be true
    end

    it 'has a valid yearly trait' do
      plan = build(:plan, :yearly)
      expect(plan).to be_valid
      expect(plan.interval).to eq('year')
    end

    it 'has a valid with_trial trait' do
      plan = build(:plan, :with_trial)
      expect(plan).to be_valid
      expect(plan.trial_days).to eq(14)
    end

    it 'has a valid with_stripe_price trait' do
      plan = build(:plan, :with_stripe_price)
      expect(plan).to be_valid
      expect(plan.stripe_price_id).to match(/^price_test_\d+$/)
    end
  end
end