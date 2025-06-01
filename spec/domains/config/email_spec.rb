# frozen_string_literal: true

require "rails_helper"

RSpec.describe Config::Email do
  describe "#initialize" do
    it "normalizes email to lowercase and strips whitespace" do
      email = described_class.new("  TEST@EXAMPLE.COM  ")
      expect(email.value).to eq("test@example.com")
    end

    it "handles nil values" do
      email = described_class.new(nil)
      expect(email.value).to be_nil
    end
  end

  describe "#valid?" do
    it "returns true for valid emails" do
      expect(described_class.new("test@example.com").valid?).to be true
      expect(described_class.new("user+tag@domain.co.uk").valid?).to be true
    end

    it "returns false for invalid emails" do
      expect(described_class.new("notanemail").valid?).to be false
      expect(described_class.new("@example.com").valid?).to be false
      expect(described_class.new("test@").valid?).to be false
      expect(described_class.new("").valid?).to be false
      expect(described_class.new(nil).valid?).to be false
    end
  end

  describe "#domain" do
    it "returns the domain part of valid email" do
      email = described_class.new("test@example.com")
      expect(email.domain).to eq("example.com")
    end

    it "returns nil for invalid email" do
      email = described_class.new("notanemail")
      expect(email.domain).to be_nil
    end
  end

  describe "#local_part" do
    it "returns the local part of valid email" do
      email = described_class.new("test@example.com")
      expect(email.local_part).to eq("test")
    end

    it "returns nil for invalid email" do
      email = described_class.new("notanemail")
      expect(email.local_part).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the email value" do
      email = described_class.new("test@example.com")
      expect(email.to_s).to eq("test@example.com")
    end

    it "returns empty string for nil value" do
      email = described_class.new(nil)
      expect(email.to_s).to eq("")
    end
  end

  describe "#==" do
    it "returns true for equal emails" do
      email1 = described_class.new("test@example.com")
      email2 = described_class.new("TEST@EXAMPLE.COM")
      expect(email1).to eq(email2)
    end

    it "returns false for different emails" do
      email1 = described_class.new("test1@example.com")
      email2 = described_class.new("test2@example.com")
      expect(email1).not_to eq(email2)
    end
  end
end