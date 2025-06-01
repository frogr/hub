# frozen_string_literal: true

require "rails_helper"

RSpec.describe Config::Color do
  describe "#initialize" do
    it "normalizes hex colors to uppercase" do
      color = described_class.new("#ff0000")
      expect(color.value).to eq("#FF0000")
    end

    it "normalizes named colors to lowercase" do
      color = described_class.new("RED")
      expect(color.value).to eq("red")
    end

    it "handles nil values" do
      color = described_class.new(nil)
      expect(color.value).to be_nil
    end
  end

  describe "#hex?" do
    it "returns true for valid hex colors" do
      expect(described_class.new("#FF0000").hex?).to be true
      expect(described_class.new("#F00").hex?).to be true
    end

    it "returns false for non-hex values" do
      expect(described_class.new("red").hex?).to be false
      expect(described_class.new("rgb(255,0,0)").hex?).to be false
    end
  end

  describe "#named?" do
    it "returns true for named colors" do
      expect(described_class.new("red").named?).to be true
      expect(described_class.new("primary").named?).to be true
    end

    it "returns false for non-named colors" do
      expect(described_class.new("#FF0000").named?).to be false
      expect(described_class.new("notacolor").named?).to be false
    end
  end

  describe "#css_var?" do
    it "returns true for CSS variables" do
      expect(described_class.new("var(--primary)").css_var?).to be true
    end

    it "returns false for non-CSS variables" do
      expect(described_class.new("#FF0000").css_var?).to be false
      expect(described_class.new("red").css_var?).to be false
    end
  end

  describe "#valid?" do
    it "returns true for valid colors" do
      expect(described_class.new("#FF0000").valid?).to be true
      expect(described_class.new("red").valid?).to be true
      expect(described_class.new("var(--primary)").valid?).to be true
    end

    it "returns false for invalid colors" do
      expect(described_class.new("notacolor").valid?).to be false
      expect(described_class.new("#GGGGGG").valid?).to be false
    end
  end

  describe "#to_css" do
    it "returns hex colors as-is" do
      expect(described_class.new("#FF0000").to_css).to eq("#FF0000")
    end

    it "returns CSS variables as-is" do
      expect(described_class.new("var(--primary)").to_css).to eq("var(--primary)")
    end

    it "converts named theme colors to CSS variables" do
      expect(described_class.new("primary").to_css).to eq("var(--primary)")
      expect(described_class.new("secondary").to_css).to eq("var(--secondary)")
    end

    it "converts standard colors to hex values" do
      expect(described_class.new("red").to_css).to eq("#FF0000")
      expect(described_class.new("black").to_css).to eq("#000000")
      expect(described_class.new("white").to_css).to eq("#FFFFFF")
    end
  end

  describe "#==" do
    it "returns true for equal colors" do
      color1 = described_class.new("#FF0000")
      color2 = described_class.new("#ff0000")
      expect(color1).to eq(color2)
    end

    it "returns false for different colors" do
      color1 = described_class.new("#FF0000")
      color2 = described_class.new("#00FF00")
      expect(color1).not_to eq(color2)
    end
  end
end