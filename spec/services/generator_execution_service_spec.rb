require "rails_helper"

RSpec.describe GeneratorExecutionService do
  let(:config) { Hub::Config.new({ "app" => { "name" => "TestApp" } }) }
  let(:dry_run) { false }
  let(:logger) { instance_double(Logger) }
  let(:service) { described_class.new(config, dry_run: dry_run, logger: logger) }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe "#execute" do
    let(:generator) { instance_double(Hub::Generator) }

    context "with valid configuration" do
      before do
        allow(Hub::Generator).to receive(:new).with(config, dry_run: dry_run).and_return(generator)
        allow(config).to receive(:valid?).and_return(true)
      end

      context "when generation succeeds" do
        before do
          allow(generator).to receive(:generate!).and_return(true)
        end

        it "returns successful result" do
          result = service.execute

          expect(result).to be_success
          expect(result.message).to eq("App regenerated successfully")
          expect(result.errors).to be_empty
        end

        it "logs success" do
          expect(logger).to receive(:info).with("App regenerated successfully with config: TestApp")
          service.execute
        end
      end

      context "when generation fails" do
        before do
          allow(generator).to receive(:generate!).and_return(false)
          allow(config).to receive_message_chain(:errors, :full_messages).and_return([ "Generation failed" ])
        end

        it "returns failure result" do
          result = service.execute

          expect(result).to be_failure
          expect(result.message).to eq("Failed to regenerate app")
          expect(result.errors).to eq([ "Generation failed" ])
        end

        it "logs failure" do
          expect(logger).to receive(:error).with("Failed to regenerate app: Generation failed")
          service.execute
        end
      end

      context "when exception occurs" do
        let(:error) { StandardError.new("Unexpected error") }

        before do
          allow(generator).to receive(:generate!).and_raise(error)
        end

        it "returns failure result with exception message" do
          result = service.execute

          expect(result).to be_failure
          expect(result.message).to eq("Error during generation")
          expect(result.errors).to eq([ "Unexpected error" ])
        end

        it "logs exception details" do
          expect(logger).to receive(:error).with("Exception during app generation: Unexpected error")
          expect(logger).to receive(:error).with(anything)
          service.execute
        end
      end
    end

    context "with invalid configuration" do
      let(:invalid_config) do
        Hub::Config.new(design: { primary_color: "invalid" })  # Invalid hex color
      end
      let(:service) { described_class.new(invalid_config, dry_run: dry_run, logger: logger) }

      it "raises InvalidConfigurationError" do
        expect { service.execute }.to raise_error(
          GeneratorExecutionService::InvalidConfigurationError,
          "Invalid configuration"
        )
      end

      it "does not call generator" do
        expect(Hub::Generator).not_to receive(:new)
        expect { service.execute }.to raise_error(GeneratorExecutionService::InvalidConfigurationError)
      end
    end

    context "with dry_run enabled" do
      let(:dry_run) { true }

      before do
        allow(config).to receive(:valid?).and_return(true)
        allow(generator).to receive(:generate!).and_return(true)
      end

      it "passes dry_run to generator" do
        expect(Hub::Generator).to receive(:new).with(config, dry_run: true).and_return(generator)
        service.execute
      end
    end
  end

  describe "Result" do
    describe "#success?" do
      it "returns true for successful result" do
        result = GeneratorExecutionService::Result.new(success: true, message: "Success")
        expect(result.success?).to be true
      end

      it "returns false for failed result" do
        result = GeneratorExecutionService::Result.new(success: false, message: "Failed")
        expect(result.success?).to be false
      end
    end

    describe "#failure?" do
      it "returns false for successful result" do
        result = GeneratorExecutionService::Result.new(success: true, message: "Success")
        expect(result.failure?).to be false
      end

      it "returns true for failed result" do
        result = GeneratorExecutionService::Result.new(success: false, message: "Failed")
        expect(result.failure?).to be true
      end
    end

    describe "attributes" do
      it "exposes message and errors" do
        result = GeneratorExecutionService::Result.new(
          success: true,
          message: "Test message",
          errors: [ "Error 1", "Error 2" ]
        )

        expect(result.message).to eq("Test message")
        expect(result.errors).to eq([ "Error 1", "Error 2" ])
      end
    end
  end
end
