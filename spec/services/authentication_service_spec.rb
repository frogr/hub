require 'rails_helper'

RSpec.describe AuthenticationService, type: :service do
  let(:user) { create(:user) }
  let(:email) { user.email }
  let(:user_agent) { 'Test Browser' }
  let(:remote_addr) { '127.0.0.1' }

  subject(:service) do
    described_class.new(
      email: email,
      user_agent: user_agent,
      remote_addr: remote_addr
    )
  end

  describe '#authenticate_with_magic_link' do
    context 'when user exists and has passwordless login enabled' do
      before do
        allow(user).to receive(:passwordless_login_enabled?).and_return(true)
      end

      it 'creates a passwordless session' do
        expect { service.authenticate_with_magic_link }
          .to change(PasswordlessSession, :count).by(1)
      end

      it 'sends a magic link email' do
        expect(UserMailer).to receive(:magic_link).with(user, instance_of(PasswordlessSession))
          .and_return(double(deliver_now: true))

        service.authenticate_with_magic_link
      end

      it 'returns success result' do
        allow(UserMailer).to receive(:magic_link).and_return(double(deliver_now: true))

        result = service.authenticate_with_magic_link

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Magic link sent to your email")
      end
    end

    context 'when user exists but passwordless login is disabled' do
      before do
        allow_any_instance_of(User).to receive(:passwordless_login_enabled?).and_return(false)
      end

      it 'returns failure result' do
        result = service.authenticate_with_magic_link

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Password login required for this account")
      end

      it 'does not create a passwordless session' do
        expect { service.authenticate_with_magic_link }
          .not_to change(PasswordlessSession, :count)
      end
    end

    context 'when user does not exist' do
      let(:email) { 'nonexistent@example.com' }

      it 'returns failure result' do
        result = service.authenticate_with_magic_link

        expect(result[:success]).to be false
        expect(result[:message]).to eq("User not found")
      end

      it 'does not create a passwordless session' do
        expect { service.authenticate_with_magic_link }
          .not_to change(PasswordlessSession, :count)
      end
    end
  end

  describe '#authenticate_with_token' do
    let(:session) { create(:passwordless_session, authenticatable: user) }
    let(:token) { session.token }

    context 'with valid token' do
      it 'claims the session' do
        service.authenticate_with_token(token)

        expect(session.reload.claimed?).to be true
      end

      it 'returns success result with user' do
        result = service.authenticate_with_token(token)

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Successfully authenticated")
        expect(result[:user]).to eq(user)
      end
    end

    context 'with invalid token' do
      let(:token) { 'invalid-token' }

      it 'returns failure result' do
        result = service.authenticate_with_token(token)

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Invalid or expired magic link")
      end
    end

    context 'with expired token' do
      let(:session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.ago) }

      it 'returns failure result' do
        result = service.authenticate_with_token(token)

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Invalid or expired magic link")
      end
    end

    context 'with already claimed token' do
      before { session.claim! }

      it 'returns failure result' do
        result = service.authenticate_with_token(token)

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Invalid or expired magic link")
      end
    end
  end
end
