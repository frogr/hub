# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auth::PasswordlessSession do
  let(:user) { create(:user) }
  let(:session_model) { create(:passwordless_session, authenticatable: user) }
  let(:auth_session) { described_class.from_model(session_model) }

  describe '.from_model' do
    it 'creates an Auth::PasswordlessSession from a model' do
      expect(auth_session).to be_a(Auth::PasswordlessSession)
      expect(auth_session.id).to eq(session_model.id)
      expect(auth_session.user_id).to eq(user.id)
      expect(auth_session.token).to eq(session_model.token)
    end

    it 'returns nil for nil input' do
      expect(described_class.from_model(nil)).to be_nil
    end
  end

  describe '.find_by_token' do
    it 'finds a session by token' do
      found_session = described_class.find_by_token(session_model.token)
      expect(found_session).to be_a(Auth::PasswordlessSession)
      expect(found_session.id).to eq(session_model.id)
    end

    it 'returns nil when not found' do
      expect(described_class.find_by_token('invalid_token')).to be_nil
    end
  end

  describe '.create_for_user' do
    it 'creates a new session for a user' do
      auth_user = Auth::User.from_model(user)
      new_session = described_class.create_for_user(auth_user)
      
      expect(new_session).to be_a(Auth::PasswordlessSession)
      expect(new_session.user_id).to eq(user.id)
      expect(new_session.expires_at).to be > Time.current
      expect(new_session.expires_at).to be <= 30.minutes.from_now
    end
  end

  describe '#expired?' do
    it 'returns false for non-expired sessions' do
      expect(auth_session.expired?).to be false
    end

    it 'returns true for expired sessions' do
      expired_session = create(:passwordless_session, expires_at: 1.hour.ago)
      auth_session = described_class.from_model(expired_session)
      expect(auth_session.expired?).to be true
    end
  end

  describe '#claimed?' do
    it 'returns false for unclaimed sessions' do
      expect(auth_session.claimed?).to be false
    end

    it 'returns true for claimed sessions' do
      claimed_session = create(:passwordless_session, claimed_at: Time.current)
      auth_session = described_class.from_model(claimed_session)
      expect(auth_session.claimed?).to be true
    end
  end

  describe '#valid_for_claim?' do
    it 'returns true for valid sessions' do
      expect(auth_session.valid_for_claim?).to be true
    end

    it 'returns false for expired sessions' do
      expired_session = create(:passwordless_session, expires_at: 1.hour.ago)
      auth_session = described_class.from_model(expired_session)
      expect(auth_session.valid_for_claim?).to be false
    end

    it 'returns false for claimed sessions' do
      claimed_session = create(:passwordless_session, claimed_at: Time.current)
      auth_session = described_class.from_model(claimed_session)
      expect(auth_session.valid_for_claim?).to be false
    end
  end

  describe '#to_model' do
    it 'returns the underlying PasswordlessSession model' do
      model = auth_session.to_model
      expect(model).to be_a(PasswordlessSession)
      expect(model.id).to eq(session_model.id)
    end
  end
end