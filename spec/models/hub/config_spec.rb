require "rails_helper"

RSpec.describe Hub::Config, type: :model do
  let(:valid_attributes) do
    {
      app: { "name" => "TestApp", "class_name" => "TestApp", "tagline" => "Test tagline" },
      branding: { "logo_text" => "TestApp", "footer_text" => "© 2024 TestApp", "support_email" => "test@example.com" },
      design: {
        "primary_color" => "#3B82F6",
        "secondary_color" => "#10B981",
        "accent_color" => "#F59E0B",
        "danger_color" => "#EF4444",
        "warning_color" => "#F59E0B",
        "info_color" => "#3B82F6",
        "success_color" => "#10B981",
        "font_family" => "Inter",
        "border_radius" => "0.375rem"
      },
      products: [
        { "name" => "Basic", "price" => 10, "stripe_price_id" => "price_basic" }
      ],
      features: { "passwordless_auth" => true, "stripe_payments" => true },
      seo: { "default_title_suffix" => " | TestApp" }
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      config = described_class.new(valid_attributes)
      expect(config).to be_valid
    end

    it "validates presence of app" do
      config = described_class.new(valid_attributes.except(:app))
      expect(config).not_to be_valid
      expect(config.errors[:app]).to be_present
    end

    it "validates app must have a name" do
      attributes = valid_attributes.deep_dup
      attributes[:app].delete("name")
      config = described_class.new(attributes)
      expect(config).not_to be_valid
      expect(config.errors[:app]).to include("must have a name")
    end

    it "validates hex color format" do
      attributes = valid_attributes.deep_dup
      attributes[:design]["primary_color"] = "invalid"
      config = described_class.new(attributes)
      expect(config).not_to be_valid
      expect(config.errors[:design]).to include("primary_color must be a valid hex color (e.g., #RRGGBB)")
    end

    it "validates product attributes" do
      attributes = valid_attributes.deep_dup
      attributes[:products] = [ { "price" => "not_a_number" } ]
      config = described_class.new(attributes)
      expect(config).not_to be_valid
      expect(config.errors[:products]).to be_present
    end
  end

  describe ".current" do
    it "loads configuration from file" do
      config = described_class.current
      expect(config).to be_a(described_class)
    end

    it "caches the configuration" do
      config1 = described_class.current
      config2 = described_class.current
      expect(config1.object_id).to eq(config2.object_id)
    end
  end

  describe ".reload!" do
    it "reloads the configuration from file" do
      config1 = described_class.current
      described_class.reload!
      config2 = described_class.current
      expect(config1.object_id).not_to eq(config2.object_id)
    end
  end

  describe "#save" do
    let(:config) { described_class.new(valid_attributes) }
    let(:temp_file) { Rails.root.join("tmp", "test_config.yml") }

    before do
      stub_const("Hub::Config::CONFIG_PATH", temp_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it "saves valid configuration to file" do
      expect(config.save).to be true
      expect(File.exist?(temp_file)).to be true

      saved_data = YAML.load_file(temp_file, permitted_classes: [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess])
      expect(saved_data["app"]["name"]).to eq("TestApp")
    end

    it "returns false for invalid configuration" do
      # Setting app to empty hash should make it invalid
      config.app = {}
      expect(config.save).to be false
      expect(File.exist?(temp_file)).to be false
    end
  end

  describe "helper methods" do
    let(:config) { described_class.new(valid_attributes) }

    it "returns app_name" do
      expect(config.app_name).to eq("TestApp")
    end

    it "returns app_class_name" do
      expect(config.app_class_name).to eq("TestApp")
    end

    it "sanitizes app_class_name" do
      config.app = { "name" => "TestApp", "class_name" => "Test-App 123" }
      expect(config.app_class_name).to eq("TestApp123")
    end

    it "returns design colors" do
      expect(config.primary_color).to eq("#3B82F6")
      expect(config.secondary_color).to eq("#10B981")
    end

    it "returns CSS variables" do
      css_vars = config.css_variables
      expect(css_vars["--color-primary"]).to eq("#3B82F6")
      expect(css_vars["--font-family"]).to eq("Inter")
    end

    it "returns feature flags" do
      expect(config.passwordless_auth_enabled?).to be true
      expect(config.stripe_payments_enabled?).to be true
    end

    it "handles missing feature flags with defaults" do
      config.features = {}
      expect(config.passwordless_auth_enabled?).to be true
    end

    it "returns branding attributes" do
      expect(config.logo_text).to eq("TestApp")
      expect(config.support_email).to eq("test@example.com")
    end

    it "generates footer text with current year" do
      config.branding = {}
      expect(config.footer_text).to include(Date.current.year.to_s)
      expect(config.footer_text).to include("TestApp")
    end
  end
end
