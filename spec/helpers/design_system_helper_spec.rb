require "rails_helper"

RSpec.describe DesignSystemHelper, type: :helper do
  describe "#design_system_css_variables" do
    let(:config) do
      instance_double(Hub::Config,
        primary_color: "#123456",
        secondary_color: "#654321",
        accent_color: "#ABCDEF",
        danger_color: "#FF0000",
        warning_color: "#FFA500",
        info_color: "#0000FF",
        success_color: "#00FF00",
        font_family: "CustomFont",
        heading_font_family: "HeadingFont",
        border_radius: "0.5rem"
      )
    end

    before do
      allow(Hub::Config).to receive(:current).and_return(config)
    end

    it "returns style tag with CSS variables" do
      result = helper.design_system_css_variables

      expect(result).to include("<style>")
      expect(result).to include("--color-primary-500: #123456")
      expect(result).to include("--color-accent-500: #ABCDEF")
      expect(result).to include("--color-secondary: #654321")
      expect(result).to include("--font-family: CustomFont")
      expect(result).to include("--border-radius: 0.5rem")
      # Check that color scales are generated
      expect(result).to include("--color-primary-50:")
      expect(result).to include("--color-primary-900:")
      expect(result).to include("--color-accent-50:")
      expect(result).to include("--color-accent-900:")
    end
  end

  describe "app helpers" do
    let(:config) do
      instance_double(Hub::Config,
        app_name: "TestApp",
        app_tagline: "Test your apps",
        app_description: "The best testing platform",
        logo_text: "TA",
        footer_text: "© 2024 TestApp",
        support_email: "help@testapp.com"
      )
    end

    before do
      allow(Hub::Config).to receive(:current).and_return(config)
    end

    it "returns app_name" do
      expect(helper.app_name).to eq("TestApp")
    end

    it "returns app_tagline" do
      expect(helper.app_tagline).to eq("Test your apps")
    end

    it "returns app_description" do
      expect(helper.app_description).to eq("The best testing platform")
    end

    it "returns logo_text" do
      expect(helper.logo_text).to eq("TA")
    end

    it "returns footer_text" do
      expect(helper.footer_text).to eq("© 2024 TestApp")
    end

    it "returns support_email" do
      expect(helper.support_email).to eq("help@testapp.com")
    end
  end

  describe "button helpers" do
    it "returns correct button classes" do
      expect(helper.btn_primary).to include(DesignSystemHelper::BTN_PRIMARY)
      expect(helper.btn_secondary).to include(DesignSystemHelper::BTN_SECONDARY)
      expect(helper.btn_accent).to include(DesignSystemHelper::BTN_ACCENT)
      expect(helper.btn_ghost).to include(DesignSystemHelper::BTN_GHOST)
      expect(helper.btn_danger).to include(DesignSystemHelper::BTN_DANGER)
    end

    it "includes size classes when specified" do
      expect(helper.btn_primary(:sm)).to include(DesignSystemHelper::BTN_SM)
      expect(helper.btn_primary(:lg)).to include(DesignSystemHelper::BTN_LG)
      expect(helper.btn_primary(:xl)).to include(DesignSystemHelper::BTN_XL)
    end
  end
end
