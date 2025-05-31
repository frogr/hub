require "rails_helper"

RSpec.describe Hub::Transformers::RubyFile do
  let(:config) do
    Hub::Config.new({
      "app" => { "name" => "MyAwesomeApp", "class_name" => "MyAwesomeApp" },
      "design" => { "primary_color" => "#FF0000" },
      "features" => { "passwordless_auth" => true }
    })
  end
  let(:transformer) { described_class.new(config, dry_run: dry_run) }
  let(:dry_run) { false }

  describe "#transform" do
    let(:temp_dir) { Rails.root.join("tmp", "ruby_transformer_test") }

    before do
      FileUtils.mkdir_p(temp_dir)
      allow(transformer).to receive(:find_files).and_return(ruby_files)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "with application controller" do
      let(:controller_file) { temp_dir.join("application_controller.rb") }
      let(:ruby_files) { [ controller_file ] }

      before do
        File.write(controller_file, <<~RUBY)
          class ApplicationController < ActionController::Base
            before_action :set_app_name
          #{'  '}
            def set_app_name
              @app_name = "Hub"
            end
          end
        RUBY
      end

      it "replaces app name references" do
        transformer.transform
        content = File.read(controller_file)
        expect(content).to include('@app_name = "MyAwesomeApp"')
        expect(content).not_to include('@app_name = "Hub"')
      end
    end

    context "with module definitions" do
      let(:module_file) { temp_dir.join("hub_module.rb") }
      let(:ruby_files) { [ module_file ] }

      before do
        File.write(module_file, <<~RUBY)
          module Hub
            class SomeClass
              def app_name
                "Hub"
              end
            end
          end
        RUBY
      end

      it "replaces module names" do
        transformer.transform
        content = File.read(module_file)
        expect(content).to include("module MyAwesomeApp")
        expect(content).not_to include("module Hub")
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }
      let(:controller_file) { temp_dir.join("test_controller.rb") }
      let(:ruby_files) { [ controller_file ] }

      before do
        File.write(controller_file, 'puts "Hub"')
      end

      it "does not modify files" do
        original_content = File.read(controller_file)
        transformer.transform
        expect(File.read(controller_file)).to eq(original_content)
      end
    end
  end

  describe "#update_ruby_file" do
    let(:temp_file) { Rails.root.join("tmp", "update_test.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(temp_file))
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it "updates multiple patterns in a single file" do
      File.write(temp_file, <<~RUBY)
        class Hub::Config
          APP_NAME = "Hub"
          def title
            "Welcome to Hub"
          end
        end
      RUBY

      transformer.send(:update_ruby_file, temp_file)
      content = File.read(temp_file)

      expect(content).to include("class MyAwesomeApp::Config")
      expect(content).to include('APP_NAME = "MyAwesomeApp"')
      expect(content).to include('"Welcome to MyAwesomeApp"')
    end
  end

  describe "#replacements" do
    it "returns correct replacement patterns" do
      replacements = transformer.send(:replacements)

      expect(replacements['"Hub"']).to eq('"MyAwesomeApp"')
      expect(replacements["'Hub'"]).to eq("'MyAwesomeApp'")
      expect(replacements["module Hub"]).to eq("module MyAwesomeApp")
      expect(replacements["Hub::"]).to eq("MyAwesomeApp::")
    end

    it "handles special characters in app name" do
      config = Hub::Config.new({
        "app" => { "name" => "My App 2.0!", "class_name" => "MyApp20" }
      })
      transformer = described_class.new(config)
      replacements = transformer.send(:replacements)

      expect(replacements["module Hub"]).to eq("module MyApp20")
    end
  end
end
