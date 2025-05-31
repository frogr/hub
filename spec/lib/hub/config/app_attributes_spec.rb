require "rails_helper"

RSpec.describe Hub::Config::AppAttributes do
  describe "attributes" do
    it "has default values" do
      app = described_class.new

      expect(app.name).to eq("Hub")
      expect(app.tagline).to eq("Ship your Rails app faster")
      expect(app.description).to eq("The fastest way to launch your SaaS")
    end

    it "accepts custom values" do
      app = described_class.new(
        name: "Custom App",
        class_name: "CustomApp",
        tagline: "Custom tagline",
        description: "Custom description"
      )

      expect(app.name).to eq("Custom App")
      expect(app.tagline).to eq("Custom tagline")
      expect(app.description).to eq("Custom description")
    end
  end

  describe "#class_name" do
    it "sanitizes class name from app name if not provided" do
      app = described_class.new(name: "My Awesome App!")
      expect(app.class_name).to eq("MyAwesomeApp")
    end

    it "uses provided class_name if given" do
      app = described_class.new(name: "My App", class_name: "CustomClassName")
      expect(app.class_name).to eq("CustomClassName")
    end

    it "removes special characters" do
      app = described_class.new(name: "App@2.0-Beta!")
      expect(app.class_name).to eq("App20Beta")
    end
  end

  describe "validations" do
    it "requires name to be present" do
      app = described_class.new(name: "")
      expect(app.valid?).to be false
      expect(app.errors[:name]).to include("can't be blank")
    end

    it "is valid with a name" do
      app = described_class.new(name: "Valid App")
      expect(app.valid?).to be true
    end
  end

  describe "#to_h" do
    it "returns attributes as hash" do
      app = described_class.new(
        name: "Test App",
        tagline: "Test tagline"
      )

      hash = app.to_h
      expect(hash).to include(
        "name" => "Test App",
        "tagline" => "Test tagline"
      )
    end
  end
end
