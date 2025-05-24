require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should have_many(:passwordless_sessions).dependent(:destroy) }
  end

  describe 'passwordless authentication' do
    context 'when passwordless_login_enabled is true' do
      let(:user) { create(:user, passwordless_login_enabled: true) }

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

    context 'when passwordless_login_enabled is false' do
      let(:user) { create(:user, passwordless_login_enabled: false) }

      it 'still allows password-based authentication' do
        expect(user.valid_password?('password123')).to be_truthy
      end

      it 'does not prefer passwordless login' do
        expect(user.passwordless_login_enabled).to be_falsy
      end
    end
  end

  describe 'defaults' do
    it 'has passwordless_login_enabled set to true by default' do
      new_user = User.new(email: 'test@example.com', password: 'password123')
      expect(new_user.passwordless_login_enabled).to be_truthy
    end
  end
end
