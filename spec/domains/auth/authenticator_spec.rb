# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auth::Authenticator do
  let(:authenticator) { described_class.new }

  describe '#request_login' do
    context 'with existing user' do
      let(:user) { create(:user, email: 'test@example.com') }

      it 'creates a session for the user' do
        result = authenticator.request_login(email: user.email)

        expect(result.success?).to be true
        expect(result.data[:user]).to be_a(Auth::User)
        expect(result.data[:user].email).to eq('test@example.com')
        expect(result.data[:session]).to be_a(Auth::PasswordlessSession)
      end
    end

    context 'with new email' do
      it 'creates a new user and session' do
        expect {
          result = authenticator.request_login(email: 'new@example.com')
          expect(result.success?).to be true
          expect(result.data[:user]).to be_a(Auth::User)
          expect(result.data[:user].email).to eq('new@example.com')
          expect(result.data[:session]).to be_a(Auth::PasswordlessSession)
        }.to change(User, :count).by(1)
      end
    end

    context 'with invalid email creation' do
      it 'returns failure when user creation fails' do
        allow_any_instance_of(User).to receive(:save).and_return(false)

        result = authenticator.request_login(email: 'invalid@example.com')
        expect(result.failure?).to be true
        expect(result.error).to eq(:invalid_email)
      end
    end
  end

  describe '#authenticate' do
    let(:user) { create(:user) }
    let(:session) { create(:passwordless_session, authenticatable: user) }

    context 'with valid token' do
      it 'authenticates the user and claims the session' do
        result = authenticator.authenticate(token: session.token)

        expect(result.success?).to be true
        expect(result.data[:user]).to be_a(Auth::User)
        expect(result.data[:user].id).to eq(user.id)

        session.reload
        expect(session.claimed_at).to be_present
      end
    end

    context 'with invalid token' do
      it 'returns failure' do
        result = authenticator.authenticate(token: 'invalid_token')

        expect(result.failure?).to be true
        expect(result.error).to eq(:invalid_token)
      end
    end

    context 'with expired token' do
      let(:expired_session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.ago) }

      it 'returns failure' do
        result = authenticator.authenticate(token: expired_session.token)

        expect(result.failure?).to be true
        expect(result.error).to eq(:expired_token)
      end
    end

    context 'with already claimed token' do
      let(:claimed_session) { create(:passwordless_session, authenticatable: user, claimed_at: Time.current) }

      it 'returns failure' do
        result = authenticator.authenticate(token: claimed_session.token)

        expect(result.failure?).to be true
        expect(result.error).to eq(:already_claimed)
      end
    end
  end

  describe '#sign_out' do
    let(:user) { create(:user) }

    before do
      create_list(:passwordless_session, 3, authenticatable: user)
      create(:passwordless_session, authenticatable: user, claimed_at: Time.current)
    end

    it 'destroys all unclaimed sessions for the user' do
      expect {
        authenticator.sign_out(user_id: user.id)
      }.to change { PasswordlessSession.where(authenticatable_type: 'User', authenticatable_id: user.id, claimed_at: nil).count }
        .from(3).to(0)
    end

    it 'does not destroy claimed sessions' do
      expect {
        authenticator.sign_out(user_id: user.id)
      }.not_to change { PasswordlessSession.where(authenticatable_type: 'User', authenticatable_id: user.id).where.not(claimed_at: nil).count }
    end

    it 'returns success' do
      result = authenticator.sign_out(user_id: user.id)
      expect(result.success?).to be true
    end
  end

  describe 'Result' do
    let(:result) { Auth::Authenticator::Result.new(success: true, data: { test: 'data' }) }

    it 'provides access to success state' do
      expect(result.success?).to be true
      expect(result.failure?).to be false
    end

    it 'provides access to data' do
      expect(result.data).to eq({ test: 'data' })
    end

    it 'provides access to error' do
      error_result = Auth::Authenticator::Result.new(success: false, error: :test_error)
      expect(error_result.error).to eq(:test_error)
    end
  end
end
