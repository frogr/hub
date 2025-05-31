require "rails_helper"

RSpec.describe ConfigurationUpdateService do
  let(:config) do
    Hub::Config.new(
      app: { name: "Hub", class_name: "Hub", tagline: "Ship faster", description: "Rails SaaS starter" },
      design: { primary_color: "#FF0000", secondary_color: "#10B981", accent_color: "#F59E0B" },
      branding: { logo_text: "Hub", support_email: "support@example.com" },
      features: { passwordless_auth: true, stripe_payments: true, admin_panel: true },
      seo: { og_image: "/og-image.png" },
      products: []
    )
  end
  let(:params) do
    {
      config_attributes: {
        app: { name: "NewApp", tagline: "New tagline" },
        design: { primary_color: "#123456" }
      },
      products: {
        "0" => { name: "Basic", price: "10", stripe_price_id: "price_123", features: "Feature 1\nFeature 2" },
        "1" => { name: "Pro", price: "20", stripe_price_id: "price_456", features: "All Basic\nPro Feature" }
      },
      apply_changes: "false"
    }
  end
  let(:service) { described_class.new(params, config) }

  describe "#execute" do
    context "with valid parameters" do
      before do
        allow_any_instance_of(ConfigurationPersistenceService).to receive(:save).and_return(true)
      end

      it "returns a successful result" do
        result = service.execute
        expect(result).to be_success
        expect(result.config).to eq(config)
      end

      it "updates configuration attributes" do
        service.execute
        expect(config.app_name).to eq("NewApp")
        expect(config.app_tagline).to eq("New tagline")
        expect(config.primary_color).to eq("#123456")
      end

      it "builds products array correctly" do
        service.execute
        expect(config.products).to eq([
          {
            "name" => "Basic",
            "price" => 10,
            "stripe_price_id" => "price_123",
            "billing_period" => "month",
            "features" => [ "Feature 1", "Feature 2" ]
          },
          {
            "name" => "Pro",
            "price" => 20,
            "stripe_price_id" => "price_456",
            "billing_period" => "month",
            "features" => [ "All Basic", "Pro Feature" ]
          }
        ])
      end

      it "persists configuration" do
        persistence_service = instance_double(ConfigurationPersistenceService)
        expect(ConfigurationPersistenceService).to receive(:new).with(config).and_return(persistence_service)
        expect(persistence_service).to receive(:save).and_return(true)

        service.execute
      end

      context "when apply_changes is true" do
        let(:params) { super().merge(apply_changes: "true") }

        it "executes generator" do
          generator_result = GeneratorExecutionService::Result.new(success: true, message: "Success")
          generator_service = instance_double(GeneratorExecutionService)

          expect(GeneratorExecutionService).to receive(:new).with(config).and_return(generator_service)
          expect(generator_service).to receive(:execute).and_return(generator_result)

          result = service.execute
          expect(result).to be_success
        end

        it "handles generator failures" do
          generator_result = GeneratorExecutionService::Result.new(
            success: false,
            message: "Failed",
            errors: [ "Generation error" ]
          )
          generator_service = instance_double(GeneratorExecutionService)

          expect(GeneratorExecutionService).to receive(:new).with(config).and_return(generator_service)
          expect(generator_service).to receive(:execute).and_return(generator_result)

          result = service.execute
          expect(result).to be_success
        end
      end
    end

    context "with invalid configuration" do
      before do
        allow(config).to receive(:valid?).and_return(false)
        allow(config).to receive_message_chain(:errors, :full_messages).and_return([ "App name is required" ])
      end

      it "returns a failure result" do
        result = service.execute
        expect(result).to be_failure
        expect(result.errors).to eq([ "App name is required" ])
      end

      it "does not persist configuration" do
        expect_any_instance_of(ConfigurationPersistenceService).not_to receive(:save)
        service.execute
      end
    end

    context "when an exception occurs" do
      before do
        allow(config).to receive(:app=).and_raise(StandardError, "Something went wrong")
      end

      it "returns a failure result with error message" do
        result = service.execute
        expect(result).to be_failure
        expect(result.errors).to eq([ "Something went wrong" ])
      end
    end
  end

  describe "#update_configuration" do
    it "updates nested attributes when present" do
      service.execute

      expect(config.app_attributes.name).to eq("NewApp")
      expect(config.design_attributes.primary_color).to eq("#123456")
    end

    it "skips nil config attributes" do
      params[:config_attributes] = { app: nil, design: { primary_color: "#FF0000" } }

      original_app = config.app_attributes
      service.execute

      expect(config.app_attributes).to eq(original_app)
      expect(config.primary_color).to eq("#FF0000")
    end
  end

  describe "Result" do
    let(:result) { ConfigurationUpdateService::Result.new(success: true, config: config, errors: []) }

    it "responds to success?" do
      expect(result.success?).to be true
    end

    it "responds to failure?" do
      expect(result.failure?).to be false
    end

    it "has accessible attributes" do
      expect(result.config).to eq(config)
      expect(result.errors).to eq([])
    end
  end
end
