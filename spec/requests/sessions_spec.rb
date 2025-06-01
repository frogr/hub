require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  include ActiveJob::TestHelper
  let(:user) { create(:user) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "GET /sessions/new" do
    it "returns http success" do
      get "/sessions/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /sessions" do
    context "when user has passwordless login enabled" do
      it "creates a passwordless session and sends magic link email" do
        expect {
          perform_enqueued_jobs do
            post "/sessions", params: { email: user.email }
          end
        }.to change(PasswordlessSession, :count).by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq('Magic link sent to your email')
      end
    end

    context "when user has passwordless login disabled" do
      before do
        allow_any_instance_of(User).to receive(:passwordless_login_enabled?).and_return(false)
      end

      it "redirects to password login" do
        post "/sessions", params: { email: user.email }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('Password login required for this account')
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

        expect(response).to redirect_to(dashboard_index_path)
        expect(flash[:notice]).to eq('Successfully authenticated')

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

  describe "DELETE /sessions/:id" do
    let(:user) { create(:user) }

    context "when user is signed in" do
      it "signs out the user and redirects to login" do
        # Simulate being signed in by setting up the session
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)

        delete "/sessions/#{user.id}"

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include('Successfully signed out!')
      end
    end
  end
end
