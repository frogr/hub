# frozen_string_literal: true

module Auth
  class PasswordlessSession
    attr_reader :id, :authenticatable_id, :authenticatable_type, :token, :expires_at, :claimed_at, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @authenticatable_id = attributes[:authenticatable_id]
      @authenticatable_type = attributes[:authenticatable_type]
      @token = attributes[:token]
      @expires_at = attributes[:expires_at]
      @claimed_at = attributes[:claimed_at]
      @created_at = attributes[:created_at]
      @updated_at = attributes[:updated_at]
    end

    def user_id
      @authenticatable_id if @authenticatable_type == "User"
    end

    def expired?
      expires_at < Time.current
    end

    def claimed?
      claimed_at.present?
    end

    def valid_for_claim?
      !expired? && !claimed?
    end

    def to_model
      ::PasswordlessSession.find(id)
    end

    class << self
      def from_model(session)
        return nil unless session

        new(
          id: session.id,
          authenticatable_id: session.authenticatable_id,
          authenticatable_type: session.authenticatable_type,
          token: session.token,
          expires_at: session.expires_at,
          claimed_at: session.claimed_at,
          created_at: session.created_at,
          updated_at: session.updated_at
        )
      end

      def find_by_token(token)
        session = ::PasswordlessSession.find_by(token: token)
        from_model(session)
      end

      def create_for_user(user)
        session = ::PasswordlessSession.create!(
          authenticatable: user.to_model,
          expires_at: 30.minutes.from_now
        )
        from_model(session)
      end
    end
  end
end
