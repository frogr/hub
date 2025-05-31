require "rails_helper"

RSpec.describe Hub::Transformers::ConfigurationFile do
  let(:config) do
    Hub::Config.new({
      "app" => { "name" => "TestApp", "class_name" => "TestApp" },
      "features" => { "passwordless_auth" => false, "stripe_payments" => true }
    })
  end
  let(:transformer) { described_class.new(config, dry_run: dry_run) }
  let(:dry_run) { false }

  describe "#transform" do
    let(:temp_dir) { Rails.root.join("tmp", "config_transformer_test") }

    before do
      FileUtils.mkdir_p(temp_dir.join("config"))
      allow(transformer).to receive(:find_files).and_return(config_files)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "with application.rb" do
      let(:app_config_file) { temp_dir.join("config", "application.rb") }
      let(:config_files) { [ app_config_file ] }

      before do
        File.write(app_config_file, <<~RUBY)
          module Hub
            class Application < Rails::Application
              config.application_name = "Hub"
            end
          end
        RUBY
      end

      it "updates module name and app references" do
        transformer.transform
        content = File.read(app_config_file)

        expect(content).to include("module TestApp")
        expect(content).to include('config.application_name = "TestApp"')
      end
    end

    context "with routes.rb" do
      let(:routes_file) { temp_dir.join("config", "routes.rb") }
      let(:config_files) { [ routes_file ] }

      before do
        File.write(routes_file, <<~RUBY)
          Rails.application.routes.draw do
            mount Hub::Engine => "/hub"
          #{'  '}
            namespace :hub do
              resources :settings
            end
          end
        RUBY
      end

      it "updates namespace references" do
        transformer.transform
        content = File.read(routes_file)

        expect(content).to include("mount TestApp::Engine")
        expect(content).to include("namespace :hub do")
      end
    end

    context "with environment configs" do
      let(:env_file) { temp_dir.join("config", "environments", "production.rb") }
      let(:config_files) { [ env_file ] }

      before do
        FileUtils.mkdir_p(File.dirname(env_file))
        File.write(env_file, <<~RUBY)
          Rails.application.configure do
            config.app_name = "Hub"
            config.cache_store = :redis_cache_store, { namespace: "hub_cache" }
          end
        RUBY
      end

      it "updates app-specific configurations" do
        transformer.transform
        content = File.read(env_file)

        expect(content).to include('config.app_name = "TestApp"')
        expect(content).to include('namespace: "hub_cache"')
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }
      let(:config_file) { temp_dir.join("config", "test.rb") }
      let(:config_files) { [ config_file ] }

      before do
        File.write(config_file, 'APP_NAME = "Hub"')
      end

      it "does not modify files" do
        original_content = File.read(config_file)
        transformer.transform
        expect(File.read(config_file)).to eq(original_content)
      end
    end
  end

  describe "#update_config_file" do
    let(:temp_file) { Rails.root.join("tmp", "update_config_test.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(temp_file))
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    it "updates multiple configuration patterns" do
      File.write(temp_file, <<~RUBY)
        module Hub
          class Application < Rails::Application
            config.app_title = "Hub Application"
            config.session_store :cookie_store, key: '_hub_session'
          end
        end
      RUBY

      transformer.send(:update_config_file, temp_file)
      content = File.read(temp_file)

      expect(content).to include("module TestApp")
      expect(content).to include('"TestApp Application"')
      expect(content).to include("key: '_hub_session'")
    end

    it "preserves Ruby syntax and indentation" do
      File.write(temp_file, <<~RUBY)
        Rails.application.configure do
          if Rails.env.production?
            config.app_name = "Hub"
          else
            config.app_name = "Hub Development"
          end
        end
      RUBY

      transformer.send(:update_config_file, temp_file)
      content = File.read(temp_file)

      expect(content).to include('config.app_name = "TestApp"')
      expect(content).to include('config.app_name = "TestApp Development"')
      expect(content).to match(/if Rails\.env\.production\?\s+config/)
    end
  end

  describe "#replacements" do
    it "returns correct replacement patterns" do
      replacements = transformer.send(:replacements)

      expect(replacements['"Hub"']).to eq('"TestApp"')
      expect(replacements["'Hub'"]).to eq("'TestApp'")
      expect(replacements["module Hub"]).to eq("module TestApp")
      expect(replacements["Hub::"]).to eq("TestApp::")
    end
  end
end
