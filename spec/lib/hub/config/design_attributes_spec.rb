require "rails_helper"

RSpec.describe Hub::Config::DesignAttributes do
  describe "attributes" do
    it "has default values" do
      design = described_class.new

      expect(design.primary_color).to eq("#3B82F6")
      expect(design.secondary_color).to eq("#10B981")
      expect(design.accent_color).to eq("#F59E0B")
      expect(design.danger_color).to eq("#EF4444")
      expect(design.warning_color).to eq("#F59E0B")
      expect(design.info_color).to eq("#3B82F6")
      expect(design.success_color).to eq("#10B981")
      expect(design.font_family).to eq("Inter")
      expect(design.border_radius).to eq("0.375rem")
    end

    it "accepts custom values" do
      design = described_class.new(
        primary_color: "#FF0000",
        font_family: "Roboto",
        heading_font_family: "Playfair Display"
      )

      expect(design.primary_color).to eq("#FF0000")
      expect(design.font_family).to eq("Roboto")
      expect(design.heading_font_family).to eq("Playfair Display")
    end
  end

  describe "#heading_font_family" do
    it "defaults to font_family if not set" do
      design = described_class.new(font_family: "Arial")
      expect(design.heading_font_family).to eq("Arial")
    end

    it "uses custom heading font if provided" do
      design = described_class.new(
        font_family: "Arial",
        heading_font_family: "Georgia"
      )
      expect(design.heading_font_family).to eq("Georgia")
    end
  end

  describe "validations" do
    it "validates hex color format" do
      design = described_class.new(primary_color: "invalid")
      expect(design.valid?).to be false
      expect(design.errors[:primary_color]).to include("must be a valid hex color (e.g., #RRGGBB)")
    end

    it "accepts valid hex colors" do
      design = described_class.new(
        primary_color: "#FF0000",
        secondary_color: "#00ff00",
        accent_color: "#0000FF"
      )
      expect(design.valid?).to be true
    end

    it "allows blank colors" do
      design = described_class.new(primary_color: "")
      expect(design.valid?).to be true
    end

    it "validates all color attributes" do
      design = described_class.new(
        primary_color: "red",
        secondary_color: "#GG0000",
        danger_color: "rgb(255,0,0)"
      )

      expect(design.valid?).to be false
      expect(design.errors[:primary_color]).to be_present
      expect(design.errors[:secondary_color]).to be_present
      expect(design.errors[:danger_color]).to be_present
    end
  end

  describe "#css_variables" do
    it "returns CSS variables hash" do
      design = described_class.new(
        primary_color: "#123456",
        font_family: "Helvetica",
        border_radius: "8px"
      )

      variables = design.css_variables

      expect(variables).to include(
        "--color-primary" => "#123456",
        "--font-family" => "Helvetica",
        "--border-radius" => "8px"
      )
    end

    it "includes all design tokens" do
      design = described_class.new
      variables = design.css_variables

      expect(variables.keys).to match_array([
        "--color-primary",
        "--color-secondary",
        "--color-accent",
        "--color-danger",
        "--color-warning",
        "--color-info",
        "--color-success",
        "--font-family",
        "--font-family-heading",
        "--border-radius"
      ])
    end
  end

  describe "#to_h" do
    it "returns attributes as hash" do
      design = described_class.new(
        primary_color: "#FF0000",
        font_family: "Roboto"
      )

      hash = design.to_h
      expect(hash).to include(
        "primary_color" => "#FF0000",
        "font_family" => "Roboto"
      )
    end
  end
end
