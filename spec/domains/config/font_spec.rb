# frozen_string_literal: true

require "rails_helper"

RSpec.describe Config::Font do
  describe "#initialize" do
    it "strips whitespace from font name" do
      font = described_class.new("  Inter  ")
      expect(font.value).to eq("Inter")
    end

    it "handles nil values" do
      font = described_class.new(nil)
      expect(font.value).to be_nil
    end
  end

  describe "#system?" do
    it "returns true for system fonts" do
      expect(described_class.new("Arial").system?).to be true
      expect(described_class.new("Helvetica Neue").system?).to be true
    end

    it "returns true for nil or empty values" do
      expect(described_class.new(nil).system?).to be true
      expect(described_class.new("").system?).to be true
    end

    it "returns false for non-system fonts" do
      expect(described_class.new("Inter").system?).to be false
    end
  end

  describe "#google?" do
    it "returns true for Google fonts" do
      expect(described_class.new("Inter").google?).to be true
      expect(described_class.new("Roboto").google?).to be true
      expect(described_class.new("Open Sans").google?).to be true
    end

    it "returns false for non-Google fonts" do
      expect(described_class.new("Arial").google?).to be false
      expect(described_class.new("CustomFont").google?).to be false
    end
  end

  describe "#custom?" do
    it "returns true for custom fonts" do
      expect(described_class.new("MyCustomFont").custom?).to be true
    end

    it "returns false for system or Google fonts" do
      expect(described_class.new("Arial").custom?).to be false
      expect(described_class.new("Inter").custom?).to be false
    end
  end

  describe "#to_css" do
    it "returns system stack for system fonts" do
      font = described_class.new("Arial")
      expect(font.to_css).to eq("system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif")
    end

    it "returns quoted font with fallback for Google fonts" do
      font = described_class.new("Inter")
      expect(font.to_css).to start_with('"Inter",')
      expect(font.to_css).to include("system-ui")
    end

    it "returns quoted font with fallback for custom fonts" do
      font = described_class.new("MyCustomFont")
      expect(font.to_css).to start_with('"MyCustomFont",')
      expect(font.to_css).to include("system-ui")
    end
  end

  describe "#to_s" do
    it "returns the font value" do
      font = described_class.new("Inter")
      expect(font.to_s).to eq("Inter")
    end

    it "returns empty string for nil value" do
      font = described_class.new(nil)
      expect(font.to_s).to eq("")
    end
  end

  describe "#==" do
    it "returns true for equal fonts" do
      font1 = described_class.new("Inter")
      font2 = described_class.new("Inter")
      expect(font1).to eq(font2)
    end

    it "returns false for different fonts" do
      font1 = described_class.new("Inter")
      font2 = described_class.new("Roboto")
      expect(font1).not_to eq(font2)
    end
  end
end
