module Hub
  class Config
    class FeatureFlags
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :passwordless_auth, :boolean, default: true
      attribute :stripe_payments, :boolean, default: true
      attribute :admin_panel, :boolean, default: true

      def passwordless_auth_enabled?
        passwordless_auth
      end

      def stripe_payments_enabled?
        stripe_payments
      end

      def admin_panel_enabled?
        admin_panel
      end

      def to_h
        attributes
      end
    end
  end
end
