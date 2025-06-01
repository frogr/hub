# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionForm do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:form) do
    described_class.new(
      user_id: user.id,
      plan_id: plan.id,
      stripe_subscription_id: 'sub_123',
      status: 'trialing'
    )
  end

  describe 'validations' do
    it 'requires user_id' do
      form.user_id = nil
      expect(form).not_to be_valid
      expect(form.errors[:user_id]).to include("can't be blank")
    end

    it 'requires plan_id' do
      form.plan_id = nil
      expect(form).not_to be_valid
      expect(form.errors[:plan_id]).to include("can't be blank")
    end

    it 'requires valid status' do
      form.status = 'invalid'
      expect(form).not_to be_valid
      expect(form.errors[:status]).to include('is not included in the list')
    end

    it 'accepts valid statuses' do
      %w[trialing active canceled past_due].each do |status|
        form.status = status
        expect(form).to be_valid
      end
    end
  end

  describe '#user' do
    it 'returns the associated user' do
      expect(form.user).to eq(user)
    end

    it 'memoizes the user lookup' do
      expect(User).to receive(:find_by).once.and_return(user)
      2.times { form.user }
    end
  end

  describe '#plan' do
    it 'returns the associated plan' do
      expect(form.plan).to eq(plan)
    end

    it 'memoizes the plan lookup' do
      expect(Plan).to receive(:find_by).once.and_return(plan)
      2.times { form.plan }
    end
  end

  describe '#save' do
    context 'with valid attributes' do
      it 'creates a subscription' do
        expect {
          expect(form.save).to be true
        }.to change(Subscription, :count).by(1)
      end

      it 'sets default trial_ends_at if not provided' do
        form.save
        subscription = Subscription.last
        expect(subscription.trial_ends_at).to be_between(13.days.from_now, 15.days.from_now)
      end


      it 'uses provided trial_ends_at' do
        custom_date = 7.days.from_now
        form.trial_ends_at = custom_date
        form.save
        subscription = Subscription.last
        expect(subscription.trial_ends_at).to be_within(1.second).of(custom_date)
      end
    end

    context 'with invalid attributes' do
      before do
        form.user_id = nil
      end

      it 'returns false' do
        expect(form.save).to be false
      end

      it 'does not create a subscription' do
        expect {
          form.save
        }.not_to change(Subscription, :count)
      end
    end

    context 'when subscription creation fails' do
      it 'transfers errors from subscription to form' do
        allow_any_instance_of(SubscriptionRepository).to receive(:create).and_return(
          Subscription.new.tap do |s|
            s.errors.add(:base, 'Something went wrong')
          end
        )

        expect(form.save).to be false
        expect(form.errors[:base]).to include('Something went wrong')
      end
    end
  end
end