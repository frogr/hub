require 'rails_helper'

RSpec.describe PasswordlessSession, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:authenticatable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:expires_at) }

    it 'is invalid without an authenticatable' do
      session = build(:passwordless_session, authenticatable: nil)
      expect(session).not_to be_valid
      expect(session.errors[:authenticatable]).to be_present
    end
  end

  describe 'scopes' do
    let!(:available_session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.from_now, claimed_at: nil) }
    let!(:claimed_session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.from_now, claimed_at: Time.current) }
    let!(:expired_session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.ago, claimed_at: nil) }

    describe '.available' do
      it 'returns only unclaimed and unexpired sessions' do
        expect(PasswordlessSession.available).to contain_exactly(available_session)
      end
    end

    describe '.expired' do
      it 'returns only expired sessions' do
        expect(PasswordlessSession.expired).to contain_exactly(expired_session)
      end
    end

    describe '.claimed' do
      it 'returns only claimed sessions' do
        expect(PasswordlessSession.claimed).to contain_exactly(claimed_session)
      end
    end
  end

  describe 'instance methods' do
    let(:session) { create(:passwordless_session, authenticatable: user, expires_at: 1.hour.from_now) }

    describe '#claim!' do
      it 'updates claimed_at timestamp' do
        expect { session.claim! }.to change(session, :claimed_at).from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    describe '#claimed?' do
      context 'when claimed_at is present' do
        before { session.update!(claimed_at: Time.current) }

        it 'returns true' do
          expect(session.claimed?).to be true
        end
      end

      context 'when claimed_at is nil' do
        it 'returns false' do
          expect(session.claimed?).to be false
        end
      end
    end

    describe '#expired?' do
      context 'when expires_at is in the past' do
        before { session.update!(expires_at: 1.hour.ago) }

        it 'returns true' do
          expect(session.expired?).to be true
        end
      end

      context 'when expires_at is in the future' do
        it 'returns false' do
          expect(session.expired?).to be false
        end
      end
    end

    describe '#available?' do
      context 'when session is not claimed and not expired' do
        it 'returns true' do
          expect(session.available?).to be true
        end
      end

      context 'when session is claimed' do
        before { session.claim! }

        it 'returns false' do
          expect(session.available?).to be false
        end
      end

      context 'when session is expired' do
        before { session.update!(expires_at: 1.hour.ago) }

        it 'returns false' do
          expect(session.available?).to be false
        end
      end
    end

    describe '#expires_in' do
      context 'when session is not expired' do
        it 'returns hours until expiration' do
          expect(session.expires_in).to be_within(0.1).of(1.0)
        end
      end

      context 'when session is expired' do
        before { session.update!(expires_at: 1.hour.ago) }

        it 'returns 0' do
          expect(session.expires_in).to eq(0)
        end
      end
    end
  end

  describe 'token generation' do
    it 'generates a token before validation on create' do
      session = build(:passwordless_session, authenticatable: user, token: nil)
      expect { session.valid? }.to change { session.token }.from(nil).to(a_string_matching(/\A[A-Za-z0-9_-]+\z/))
    end

    it 'generates a 32-byte URL-safe base64 token' do
      session = create(:passwordless_session, authenticatable: user)
      expect(session.token).to be_present
      expect(session.token.length).to be >= 43 # 32 bytes in base64 is at least 43 chars
    end

    it 'generates unique tokens for different sessions' do
      session1 = create(:passwordless_session, authenticatable: user)
      session2 = create(:passwordless_session, authenticatable: user)
      expect(session1.token).not_to eq(session2.token)
    end

    it 'does not regenerate token on update' do
      session = create(:passwordless_session, authenticatable: user)
      original_token = session.token
      session.update!(expires_at: 2.hours.from_now)
      expect(session.token).to eq(original_token)
    end
  end
end
