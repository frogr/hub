require "rails_helper"

RSpec.describe ConfigurationPersistenceService do
  let(:config) do
    Hub::Config.new({
      "app" => { "name" => "TestApp" },
      "design" => { "primary_color" => "#FF0000" }
    })
  end
  let(:config_path) { Rails.root.join("tmp", "test_hub_config.yml") }
  let(:service) { described_class.new(config, config_path) }

  before do
    FileUtils.mkdir_p(File.dirname(config_path))
  end

  after do
    FileUtils.rm_f(config_path)
  end

  describe "#save" do
    context "when successful" do
      it "writes configuration to YAML file" do
        expect(service.save).to be true
        expect(File.exist?(config_path)).to be true

        saved_data = YAML.load_file(config_path)
        expect(saved_data["app"]["name"]).to eq("TestApp")
        expect(saved_data["design"]["primary_color"]).to eq("#FF0000")
      end

      it "creates directory if it doesn't exist" do
        nested_path = Rails.root.join("tmp", "nested", "dir", "config.yml")
        service = described_class.new(config, nested_path)

        expect(service.save).to be true
        expect(File.exist?(nested_path)).to be true

        FileUtils.rm_rf(Rails.root.join("tmp", "nested"))
      end
    end

    context "when an error occurs" do
      before do
        allow(File).to receive(:write).and_raise(StandardError, "Write error")
      end

      it "returns false" do
        expect(service.save).to be false
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with("Failed to save configuration: Write error")
        service.save
      end
    end
  end

  describe "#load" do
    context "when config file exists" do
      before do
        File.write(config_path, {
          "app" => { "name" => "LoadedApp", "tagline" => "Loaded tagline" },
          "design" => { "primary_color" => "#00FF00" },
          "products" => [ { "name" => "Basic", "price" => 10 } ]
        }.to_yaml)
      end

      it "loads configuration from file" do
        loaded_config = service.load

        expect(loaded_config.app_name).to eq("LoadedApp")
        expect(loaded_config.app_tagline).to eq("Loaded tagline")
        expect(loaded_config.primary_color).to eq("#00FF00")
        expect(loaded_config.products).to eq([ { "name" => "Basic", "price" => 10 } ])
      end

      it "assigns attributes to existing config object" do
        service.load

        expect(config.app_name).to eq("LoadedApp")
        expect(config.primary_color).to eq("#00FF00")
      end
    end

    context "when config file does not exist" do
      it "returns default config" do
        loaded_config = service.load

        expect(loaded_config).to eq(config)
        expect(loaded_config.app_name).to eq("TestApp")
      end
    end

    context "when YAML file is invalid" do
      before do
        File.write(config_path, "invalid: yaml: content: [")
      end

      it "returns default config" do
        loaded_config = service.load
        expect(loaded_config).to eq(config)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to load configuration:/)
        service.load
      end
    end
  end

  describe "#config_data" do
    it "returns configuration attributes as hash" do
      data = service.send(:config_data)

      expect(data).to be_a(Hash)
      expect(data["app"]["name"]).to eq("TestApp")
      expect(data["design"]["primary_color"]).to eq("#FF0000")
    end
  end
end
