require "rails_helper"

RSpec.describe Hub::Generator do
  let(:config) { instance_double(Hub::Config, valid?: true) }
  let(:generator) { described_class.new(config) }

  describe "#initialize" do
    it "uses provided config" do
      expect(generator.config).to eq(config)
    end

    it "uses Hub::Config.current when no config provided" do
      allow(Hub::Config).to receive(:current).and_return(config)
      generator = described_class.new
      expect(generator.config).to eq(config)
    end
  end

  describe "#generate!" do
    before do
      allow(config).to receive(:app_name).and_return("TestApp")
      allow(config).to receive(:primary_color).and_return("#123456")
      allow(config).to receive(:products).and_return([])
      allow(config).to receive(:errors).and_return(double(full_messages: []))
    end

    context "with valid config" do
      before do
        # Mock all transformer classes
        [ Hub::Transformers::RubyFile,
         Hub::Transformers::ViewFile,
         Hub::Transformers::Stylesheet,
         Hub::Transformers::ConfigurationFile ].each do |klass|
          transformer_instance = instance_double(klass)
          allow(klass).to receive(:new).and_return(transformer_instance)
          allow(transformer_instance).to receive(:transform)
        end
      end

      it "runs all transformers" do
        expect(generator.generate!).to be true
      end

      it "passes dry_run option to transformers" do
        generator = described_class.new(config, dry_run: true)

        expect(Hub::Transformers::RubyFile).to receive(:new).with(config, dry_run: true)
        expect(Hub::Transformers::ViewFile).to receive(:new).with(config, dry_run: true)
        expect(Hub::Transformers::Stylesheet).to receive(:new).with(config, dry_run: true)
        expect(Hub::Transformers::ConfigurationFile).to receive(:new).with(config, dry_run: true)

        generator.generate!
      end
    end

    context "with invalid config" do
      before do
        allow(config).to receive(:valid?).and_return(false)
        allow(config).to receive(:errors).and_return(
          double(full_messages: [ "App name is required" ])
        )
      end

      it "returns false and displays errors" do
        expect(generator.generate!).to be false
      end
    end

    context "when transformer raises error" do
      before do
        transformer_instance = instance_double(Hub::Transformers::RubyFile)
        allow(Hub::Transformers::RubyFile).to receive(:new).and_return(transformer_instance)
        allow(transformer_instance).to receive(:transform).and_raise("Test error")
      end

      it "returns false and displays error" do
        expect(generator.generate!).to be false
      end
    end
  end

  describe ".run!" do
    it "creates new instance and calls generate!" do
      generator_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(nil, dry_run: true).and_return(generator_instance)
      allow(generator_instance).to receive(:generate!).and_return(true)

      result = described_class.run!(dry_run: true)
      expect(result).to be true
    end
  end
end
