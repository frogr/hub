# frozen_string_literal: true

module Auth
  class Authenticator
    def initialize(user_repository: User, session_repository: PasswordlessSession)
      @user_repository = user_repository
      @session_repository = session_repository
    end

    def request_login(email:)
      user = find_or_create_user(email)
      return failure(:invalid_email) unless user

      session = @session_repository.create_for_user(user)
      return failure(:session_creation_failed) unless session

      success(user: user, session: session)
    end

    def authenticate(token:)
      session = @session_repository.find_by_token(token)
      return failure(:invalid_token) unless session

      return failure(:expired_token) if session.expired?
      return failure(:already_claimed) if session.claimed?

      user = @user_repository.find(session.user_id)
      return failure(:user_not_found) unless user

      claim_session(session)
      success(user: user)
    end

    def sign_out(user_id:)
      ::PasswordlessSession.where(authenticatable_type: "User", authenticatable_id: user_id, claimed_at: nil).destroy_all
      success
    end

    private

    def find_or_create_user(email)
      user = @user_repository.find_by_email(email)
      return user if user

      # Skip password validation for passwordless users
      model = ::User.new(email: email)
      model.skip_password_validation = true if model.respond_to?(:skip_password_validation=)
      model.save(validate: false) # Skip validations for passwordless flow
      @user_repository.from_model(model) if model.persisted?
    end

    def claim_session(session)
      session.to_model.update!(claimed_at: Time.current)
    end

    def success(data = {})
      Result.new(success: true, data: data)
    end

    def failure(error, data = {})
      Result.new(success: false, error: error, data: data)
    end

    class Result
      attr_reader :data, :error

      def initialize(success:, data: {}, error: nil)
        @success = success
        @data = data
        @error = error
      end

      def success?
        @success
      end

      def failure?
        !@success
      end
    end
  end
end
