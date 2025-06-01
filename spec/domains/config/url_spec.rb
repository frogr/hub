# frozen_string_literal: true

require "rails_helper"

RSpec.describe Config::Url do
  describe "#initialize" do
    it "strips whitespace from URL" do
      url = described_class.new("  https://example.com  ")
      expect(url.value).to eq("https://example.com")
    end

    it "handles nil values" do
      url = described_class.new(nil)
      expect(url.value).to be_nil
    end
  end

  describe "#valid?" do
    it "returns true for valid HTTP URLs" do
      expect(described_class.new("http://example.com").valid?).to be true
      expect(described_class.new("https://example.com").valid?).to be true
      expect(described_class.new("https://example.com/path?query=value").valid?).to be true
    end

    it "returns false for invalid URLs" do
      expect(described_class.new("notaurl").valid?).to be false
      expect(described_class.new("ftp://example.com").valid?).to be false
      expect(described_class.new("").valid?).to be false
      expect(described_class.new(nil).valid?).to be false
    end
  end

  describe "#scheme" do
    it "returns the scheme for valid URL" do
      url = described_class.new("https://example.com")
      expect(url.scheme).to eq("https")
    end

    it "returns nil for invalid URL" do
      url = described_class.new("notaurl")
      expect(url.scheme).to be_nil
    end
  end

  describe "#host" do
    it "returns the host for valid URL" do
      url = described_class.new("https://example.com:8080/path")
      expect(url.host).to eq("example.com")
    end

    it "returns nil for invalid URL" do
      url = described_class.new("notaurl")
      expect(url.host).to be_nil
    end
  end

  describe "#path" do
    it "returns the path for valid URL" do
      url = described_class.new("https://example.com/path/to/resource")
      expect(url.path).to eq("/path/to/resource")
    end

    it "returns root path when no path specified" do
      url = described_class.new("https://example.com")
      expect(url.path).to eq("/")
    end

    it "returns nil for invalid URL" do
      url = described_class.new("notaurl")
      expect(url.path).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the URL value" do
      url = described_class.new("https://example.com")
      expect(url.to_s).to eq("https://example.com")
    end

    it "returns empty string for nil value" do
      url = described_class.new(nil)
      expect(url.to_s).to eq("")
    end
  end

  describe "#==" do
    it "returns true for equal URLs" do
      url1 = described_class.new("https://example.com")
      url2 = described_class.new("https://example.com")
      expect(url1).to eq(url2)
    end

    it "returns false for different URLs" do
      url1 = described_class.new("https://example.com")
      url2 = described_class.new("https://different.com")
      expect(url1).not_to eq(url2)
    end
  end
end