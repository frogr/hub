require "rails_helper"
require "fileutils"

RSpec.describe Hub::Transformers::Base do
  let(:config) { instance_double(Hub::Config) }
  let(:transformer) { described_class.new(config) }

  describe "#initialize" do
    it "sets config and dry_run" do
      transformer = described_class.new(config, dry_run: true)
      expect(transformer.config).to eq(config)
      expect(transformer.dry_run).to be true
    end
  end

  describe "#transform" do
    it "raises NotImplementedError" do
      expect { transformer.transform }.to raise_error(NotImplementedError)
    end
  end

  describe "protected methods" do
    # Create a test subclass to access protected methods
    let(:test_class) do
      Class.new(described_class) do
        def transform; end

        def test_write_file(path, content)
          write_file(path, content)
        end

        def test_safe_class_name(name)
          safe_class_name(name)
        end

        def test_safe_constant_name(name)
          safe_constant_name(name)
        end
      end
    end

    let(:test_transformer) { test_class.new(config) }
    let(:test_file) { Rails.root.join("tmp", "test_transformer_file.txt") }

    after do
      FileUtils.rm_f(test_file)
    end

    describe "#write_file" do
      it "writes content to file" do
        test_transformer.test_write_file(test_file, "test content")
        expect(File.read(test_file)).to eq("test content")
      end

      it "does not write in dry_run mode" do
        dry_transformer = test_class.new(config, dry_run: true)
        dry_transformer.test_write_file(test_file, "test content")
        expect(File.exist?(test_file)).to be false
      end
    end

    describe "#safe_class_name" do
      it "converts name to safe class name" do
        expect(test_transformer.test_safe_class_name("My App")).to eq("MyApp")
        expect(test_transformer.test_safe_class_name("my-app-123")).to eq("MyApp123")
        expect(test_transformer.test_safe_class_name("app@#$%name")).to eq("AppName")
      end
    end

    describe "#safe_constant_name" do
      it "converts name to safe constant name" do
        expect(test_transformer.test_safe_constant_name("My App")).to eq("MY_APP")
        expect(test_transformer.test_safe_constant_name("my-app-123")).to eq("MY_APP_123")
      end
    end
  end
end
