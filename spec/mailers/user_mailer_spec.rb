require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "magic_link" do
    let(:user) { create(:user) }
    let(:passwordless_session) { user.passwordless_with(user_agent: 'test', remote_addr: '127.0.0.1') }
    let(:mail) { UserMailer.magic_link(user, passwordless_session) }

    it "renders the headers" do
      expect(mail.subject).to eq("Sign in to your account")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi #{user.email}")
      expect(mail.body.encoded).to match("Sign in")
    end
  end
end
