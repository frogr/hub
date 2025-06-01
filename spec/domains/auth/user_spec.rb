# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auth::User do
  let(:user_model) { create(:user, email: 'test@example.com', admin: true) }
  let(:auth_user) { described_class.from_model(user_model) }

  describe '.from_model' do
    it 'creates an Auth::User from a User model' do
      expect(auth_user).to be_a(Auth::User)
      expect(auth_user.id).to eq(user_model.id)
      expect(auth_user.email).to eq('test@example.com')
      expect(auth_user.admin?).to be true
    end

    it 'returns nil for nil input' do
      expect(described_class.from_model(nil)).to be_nil
    end
  end

  describe '.find' do
    it 'finds a user by id' do
      found_user = described_class.find(user_model.id)
      expect(found_user).to be_a(Auth::User)
      expect(found_user.id).to eq(user_model.id)
    end

    it 'returns nil when not found' do
      expect(described_class.find(999999)).to be_nil
    end
  end

  describe '.find_by_email' do
    it 'finds a user by email' do
      user_model # ensure user is created
      found_user = described_class.find_by_email('test@example.com')
      expect(found_user).to be_a(Auth::User)
      expect(found_user.email).to eq('test@example.com')
    end

    it 'returns nil when not found' do
      expect(described_class.find_by_email('nonexistent@example.com')).to be_nil
    end
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      expect(auth_user.admin?).to be true
    end

    it 'returns false for non-admin users' do
      non_admin = create(:user, admin: false)
      auth_user = described_class.from_model(non_admin)
      expect(auth_user.admin?).to be false
    end
  end

  describe '#passwordless_login_enabled?' do
    it 'always returns true' do
      expect(auth_user.passwordless_login_enabled?).to be true
    end
  end

  describe '#to_model' do
    it 'returns the underlying User model' do
      model = auth_user.to_model
      expect(model).to be_a(User)
      expect(model.id).to eq(user_model.id)
    end
  end
end
