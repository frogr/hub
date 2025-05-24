require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /sessions/new" do
    it "returns http success" do
      get "/sessions/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /sessions" do
    context "when user has passwordless login enabled" do
      let(:user) { create(:user, passwordless_login_enabled: true) }

      it "creates a passwordless session and sends magic link email" do
        expect {
          post "/sessions", params: { email: user.email }
        }.to change(PasswordlessSession, :count).by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include('Check your email for a magic link!')
      end
    end

    context "when user has passwordless login disabled" do
      let(:user) { create(:user, passwordless_login_enabled: false) }

      it "redirects to password login" do
        post "/sessions", params: { email: user.email }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('Please use password login')
      end
    end

    context "when user does not exist" do
      it "shows error message" do
        post "/sessions", params: { email: "nonexistent@example.com" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include('User not found')
      end
    end
  end

  describe "GET /sign_in/:token" do
    let(:passwordless_session) { user.passwordless_with(user_agent: 'test', remote_addr: '127.0.0.1') }

    context "with valid token" do
      it "signs in the user and marks session as claimed" do
        get "/sign_in/#{passwordless_session.token}"

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Successfully signed in!')

        passwordless_session.reload
        expect(passwordless_session.claimed_at).to be_present
      end
    end

    context "with invalid token" do
      it "redirects with error message" do
        get "/sign_in/invalid_token"

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include('Invalid or expired magic link')
      end
    end

    context "with expired token" do
      it "redirects with error message" do
        passwordless_session.update!(expires_at: 1.hour.ago)

        get "/sign_in/#{passwordless_session.token}"

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include('Invalid or expired magic link')
      end
    end
  end
end
