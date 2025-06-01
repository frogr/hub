# frozen_string_literal: true

module Auth
  class User
    attr_reader :id, :email, :admin, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @email = attributes[:email]
      @admin = attributes[:admin] || false
      @created_at = attributes[:created_at]
      @updated_at = attributes[:updated_at]
    end

    def admin?
      @admin == true
    end

    def passwordless_login_enabled?
      true
    end

    def to_model
      ::User.find(id)
    end

    class << self
      def from_model(user)
        return nil unless user

        new(
          id: user.id,
          email: user.email,
          admin: user.admin?,
          created_at: user.created_at,
          updated_at: user.updated_at
        )
      end

      def find(id)
        user = ::User.find_by(id: id)
        from_model(user)
      end

      def find_by_email(email)
        user = ::User.find_by(email: email)
        from_model(user)
      end
    end
  end
end
