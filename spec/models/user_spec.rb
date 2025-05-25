require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should have_many(:passwordless_sessions).dependent(:destroy) }
  end

  describe 'passwordless authentication' do
    it 'creates a passwordless session' do
      session_params = {
        user_agent: 'Mozilla/5.0',
        remote_addr: '127.0.0.1'
      }

      expect {
        user.passwordless_with(**session_params)
      }.to change(PasswordlessSession, :count).by(1)

      session = user.passwordless_sessions.last
      expect(session.user_agent).to eq('Mozilla/5.0')
      expect(session.remote_addr).to eq('127.0.0.1')
      expect(session.expires_at).to be_present
      expect(session.token).to be_present
    end

    it 'allows signing in via magic link' do
      session_params = {
        user_agent: 'Mozilla/5.0',
        remote_addr: '127.0.0.1'
      }

      passwordless_session = user.passwordless_with(**session_params)

      expect(passwordless_session).to be_persisted
      expect(passwordless_session.claimed_at).to be_nil
      expect(passwordless_session.expires_at).to be > Time.current
    end
  end

  describe '#passwordless_login_enabled?' do
    it 'returns true by default' do
      expect(user.passwordless_login_enabled?).to be true
    end
  end

  describe '#can_authenticate_with_password?' do
    context 'when user has encrypted password' do
      it 'returns true' do
        expect(user.can_authenticate_with_password?).to be true
      end
    end

    context 'when user has no encrypted password' do
      let(:user) { User.new(email: 'test@example.com') }

      it 'returns false' do
        expect(user.can_authenticate_with_password?).to be false
      end
    end
  end

  describe '#authentication_method' do
    context 'when passwordless login is enabled' do
      it 'returns :passwordless' do
        expect(user.authentication_method).to eq(:passwordless)
      end
    end

    context 'when passwordless login is disabled but password exists' do
      before do
        allow(user).to receive(:passwordless_login_enabled?).and_return(false)
      end

      it 'returns :password' do
        expect(user.authentication_method).to eq(:password)
      end
    end

    context 'when no authentication method is available' do
      let(:user) { User.new(email: 'test@example.com') }

      before do
        allow(user).to receive(:passwordless_login_enabled?).and_return(false)
      end

      it 'returns :none' do
        expect(user.authentication_method).to eq(:none)
      end
    end
  end
end
