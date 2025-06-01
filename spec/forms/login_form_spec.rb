# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoginForm do
  let(:form) { described_class.new(email: email) }
  let(:email) { 'test@example.com' }

  describe 'validations' do
    it 'requires email' do
      form = described_class.new(email: '')
      expect(form).not_to be_valid
      expect(form.errors[:email]).to include("can't be blank")
    end

    it 'requires valid email format' do
      form = described_class.new(email: 'invalid-email')
      expect(form).not_to be_valid
      expect(form.errors[:email]).to include('is invalid')
    end
  end

  describe '#request_login' do
    context 'with valid email' do
      let(:user) { create(:user, email: email) }

      before do
        user # ensure user exists
      end

      it 'creates a login session' do
        expect(form.request_login).to be true
        expect(form.user).to be_a(Auth::User)
        expect(form.session).to be_a(Auth::PasswordlessSession)
      end

      it 'normalizes email' do
        # Create a new user and test normalization
        form = described_class.new(email: '  UNIQUE_TEST@EXAMPLE.COM  ')
        result = form.request_login
        unless result
          puts "Errors: #{form.errors.full_messages}"
        end
        expect(result).to be true
        expect(form.user).not_to be_nil
        expect(form.user.email).to eq('unique_test@example.com')
      end
    end

    context 'with new email' do
      it 'creates a new user and session' do
        expect {
          expect(form.request_login).to be true
        }.to change(User, :count).by(1)
      end
    end

    context 'with invalid form' do
      let(:email) { 'invalid' }

      it 'returns false without making requests' do
        expect(form.request_login).to be false
        expect(form.user).to be_nil
        expect(form.session).to be_nil
      end
    end

    context 'when authenticator fails' do
      it 'adds appropriate error message' do
        authenticator = instance_double(Auth::Authenticator)
        result = Auth::Authenticator::Result.new(success: false, error: :session_creation_failed)

        allow(Auth::Authenticator).to receive(:new).and_return(authenticator)
        allow(authenticator).to receive(:request_login).and_return(result)

        expect(form.request_login).to be false
        expect(form.errors[:base]).to include('Could not create login session. Please try again.')
      end
    end
  end

  describe '#save' do
    it 'delegates to request_login' do
      expect(form).to receive(:request_login).and_return(true)
      form.save
    end
  end
end
