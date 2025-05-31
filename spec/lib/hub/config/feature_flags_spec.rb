require "rails_helper"

RSpec.describe Hub::Config::FeatureFlags do
  describe "attributes" do
    it "has default values" do
      features = described_class.new

      expect(features.passwordless_auth).to be true
      expect(features.stripe_payments).to be true
      expect(features.admin_panel).to be true
    end

    it "accepts custom values" do
      features = described_class.new(
        passwordless_auth: false,
        stripe_payments: true,
        admin_panel: false
      )

      expect(features.passwordless_auth).to be false
      expect(features.stripe_payments).to be true
      expect(features.admin_panel).to be false
    end
  end

  describe "enabled? methods" do
    context "when features are enabled" do
      let(:features) { described_class.new }

      it "#passwordless_auth_enabled? returns true" do
        expect(features.passwordless_auth_enabled?).to be true
      end

      it "#stripe_payments_enabled? returns true" do
        expect(features.stripe_payments_enabled?).to be true
      end

      it "#admin_panel_enabled? returns true" do
        expect(features.admin_panel_enabled?).to be true
      end
    end

    context "when features are disabled" do
      let(:features) do
        described_class.new(
          passwordless_auth: false,
          stripe_payments: false,
          admin_panel: false
        )
      end

      it "#passwordless_auth_enabled? returns false" do
        expect(features.passwordless_auth_enabled?).to be false
      end

      it "#stripe_payments_enabled? returns false" do
        expect(features.stripe_payments_enabled?).to be false
      end

      it "#admin_panel_enabled? returns false" do
        expect(features.admin_panel_enabled?).to be false
      end
    end
  end

  describe "#to_h" do
    it "returns attributes as hash" do
      features = described_class.new(
        passwordless_auth: true,
        stripe_payments: false,
        admin_panel: true
      )

      hash = features.to_h
      expect(hash).to eq({
        "passwordless_auth" => true,
        "stripe_payments" => false,
        "admin_panel" => true
      })
    end
  end
end
