# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionRepository do
  let(:repository) { described_class.new }
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }

  describe '#find' do
    let(:subscription) { create(:subscription, user: user) }

    it 'finds a subscription by id' do
      found = repository.find(subscription.id)
      expect(found).to eq(subscription)
    end

    it 'returns nil when not found' do
      expect(repository.find(999999)).to be_nil
    end
  end

  describe '#find_by_user' do
    let!(:subscriptions) { create_list(:subscription, 3, user: user) }
    let!(:other_subscription) { create(:subscription) }

    it 'returns all subscriptions for the user' do
      results = repository.find_by_user(user)
      expect(results.count).to eq(3)
      expect(results).to match_array(subscriptions)
    end
  end

  describe '#active_for_user' do
    let!(:active_subscription) { create(:subscription, user: user, status: 'active') }
    let!(:cancelled_subscription) { create(:subscription, user: user, status: 'canceled') }
    let!(:trialing_subscription) { create(:subscription, user: user, status: 'trialing') }

    it 'returns the most recent active subscription' do
      result = repository.active_for_user(user)
      expect(result).to eq(active_subscription)
    end

    it 'returns nil when no active subscription exists' do
      user_without_active = create(:user)
      expect(repository.active_for_user(user_without_active)).to be_nil
    end
  end

  describe '#active_or_trialing_for_user' do
    let!(:active_subscription) { create(:subscription, user: user, status: 'active', created_at: 1.day.ago) }
    let!(:trialing_subscription) { create(:subscription, user: user, status: 'trialing', created_at: Time.current) }
    let!(:cancelled_subscription) { create(:subscription, user: user, status: 'canceled') }

    it 'returns the most recent active or trialing subscription' do
      result = repository.active_or_trialing_for_user(user)
      expect(result).to eq(trialing_subscription)
    end
  end

  describe '#all_for_user' do
    let!(:subscriptions) { create_list(:subscription, 3, user: user, plan: plan) }

    it 'returns all subscriptions with plans included' do
      results = repository.all_for_user(user)
      expect(results.count).to eq(3)
      expect(results.first.association(:plan)).to be_loaded
    end

    it 'orders by created_at descending' do
      results = repository.all_for_user(user)
      expect(results).to eq(subscriptions.reverse)
    end
  end

  describe '#create' do
    it 'creates a new subscription' do
      attributes = {
        user_id: user.id,
        plan_id: plan.id,
        status: 'trialing',
        trial_ends_at: 14.days.from_now
      }

      subscription = repository.create(attributes)
      expect(subscription).to be_persisted
      expect(subscription.user).to eq(user)
      expect(subscription.plan).to eq(plan)
    end
  end

  describe '#update' do
    let(:subscription) { create(:subscription, status: 'trialing') }

    it 'updates the subscription' do
      updated = repository.update(subscription, status: 'active')
      expect(updated.status).to eq('active')
      expect(subscription.reload.status).to eq('active')
    end
  end

  describe '#cancel' do
    let(:subscription) { create(:subscription, status: 'active') }

    it 'cancels the subscription' do
      result = repository.cancel(subscription)
      expect(result).to be true
      
      subscription.reload
      expect(subscription.status).to eq('canceled')
      expect(subscription.cancel_at_period_end).to be true
    end
  end

  describe '#expired' do
    let!(:expired_active) { create(:subscription, status: 'active', current_period_end: 1.day.ago) }
    let!(:expired_trialing) { create(:subscription, status: 'trialing', current_period_end: 1.day.ago) }
    let!(:active_valid) { create(:subscription, status: 'active', current_period_end: 1.day.from_now) }
    let!(:canceled) { create(:subscription, status: 'canceled', current_period_end: 1.day.ago) }

    it 'returns only expired active or trialing subscriptions' do
      results = repository.expired
      expect(results).to include(expired_active, expired_trialing)
      expect(results).not_to include(active_valid, canceled)
    end
  end

  describe '#ending_trial_soon' do
    let!(:ending_soon) { create(:subscription, status: 'trialing', trial_ends_at: 2.days.from_now) }
    let!(:ending_later) { create(:subscription, status: 'trialing', trial_ends_at: 5.days.from_now) }
    let!(:already_ended) { create(:subscription, status: 'trialing', trial_ends_at: 1.day.ago) }
    let!(:active) { create(:subscription, status: 'active', trial_ends_at: 2.days.from_now) }

    it 'returns trials ending within specified days' do
      results = repository.ending_trial_soon(3)
      expect(results).to include(ending_soon)
      expect(results).not_to include(ending_later, already_ended, active)
    end
  end

  describe '#statistics' do
    before do
      create_list(:subscription, 2, status: 'active', plan: create(:plan, amount: 1000))
      create_list(:subscription, 3, status: 'trialing')
      create(:subscription, status: 'canceled')
    end

    it 'returns subscription statistics' do
      stats = repository.statistics
      
      expect(stats[:total]).to eq(6)
      expect(stats[:active]).to eq(2)
      expect(stats[:trialing]).to eq(3)
      expect(stats[:cancelled]).to eq(1)
      expect(stats[:revenue]).to eq(20.0) # 2 * $10
    end
  end
end