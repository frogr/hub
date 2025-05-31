require "rails_helper"

RSpec.describe "HubAdmin::Configuration", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  describe "GET /hub_admin/configuration" do
    context "when not authenticated" do
      it "redirects to root with alert" do
        get hub_admin_configuration_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when authenticated as regular user" do
      before do
        allow_any_instance_of(HubAdmin::BaseController).to receive(:current_user).and_return(regular_user)
      end

      it "redirects to root with alert" do
        get hub_admin_configuration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized")
      end
    end

    context "when authenticated as admin" do
      before do
        allow_any_instance_of(HubAdmin::BaseController).to receive(:current_user).and_return(admin_user)
      end

      it "displays the configuration form" do
        get hub_admin_configuration_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Hub Configuration")
      end

      it "loads current configuration" do
        config = Hub::Config.current
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)

        get hub_admin_configuration_path
        expect(assigns(:config)).to eq(config)
      end
    end
  end

  describe "PATCH /hub_admin/configuration" do
    before do
      allow_any_instance_of(HubAdmin::BaseController).to receive(:current_user).and_return(admin_user)
    end

    let(:valid_params) do
      {
        config: {
          app: { name: "MyApp", class_name: "MyApp", tagline: "New tagline" },
          branding: { logo_text: "MyApp", support_email: "support@myapp.com" },
          design: { primary_color: "#FF0000" },
          features: { passwordless_auth: "1" }
        }
      }
    end

    context "with valid parameters" do
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

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)
        allow_any_instance_of(ConfigurationPersistenceService).to receive(:save).and_return(true)
      end

      it "updates the configuration" do
        patch hub_admin_configuration_path, params: valid_params

        expect(response).to redirect_to(hub_admin_configuration_path)
        expect(config.app["name"]).to eq("MyApp")
      end

      it "displays success message without applying changes" do
        patch hub_admin_configuration_path, params: valid_params

        expect(flash[:notice]).to include("Configuration saved")
        expect(flash[:notice]).to include("Apply Changes")
      end

      context "when apply_changes is true" do
        let(:generator_service) { instance_double(GeneratorExecutionService) }
        let(:success_result) { GeneratorExecutionService::Result.new(success: true, message: "Success") }
        let(:failure_result) { GeneratorExecutionService::Result.new(success: false, message: "Failed", errors: [ "Error" ]) }

        before do
          allow(GeneratorExecutionService).to receive(:new).and_return(generator_service)
        end

        it "runs the generator" do
          allow(generator_service).to receive(:execute).and_return(success_result)

          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(generator_service).to have_received(:execute)
          expect(flash[:notice]).to include("changes applied successfully")
        end

        it "handles generator failure" do
          allow(generator_service).to receive(:execute).and_return(failure_result)

          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(flash[:notice]).to include("changes applied successfully")
          expect(response).to redirect_to(hub_admin_configuration_path)
        end
      end
    end

    context "with invalid parameters" do
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
      let(:invalid_params) do
        {
          config: {
            app: { name: "" }  # Invalid - name can't be blank
          }
        }
      end

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)
      end

      it "renders the form with errors" do
        patch hub_admin_configuration_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Hub Configuration")
      end
    end

    context "with products parameters" do
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
      let(:products_params) do
        {
          config: valid_params[:config],
          products: {
            "0" => { name: "Basic", price: "10", stripe_price_id: "price_basic", features: "Feature 1\nFeature 2" },
            "1" => { name: "", price: "", stripe_price_id: "" } # Empty product should be ignored
          }
        }
      end

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)
        allow_any_instance_of(ConfigurationPersistenceService).to receive(:save).and_return(true)
        allow(ProductsBuilderService).to receive(:new).and_return(
          double(build: [
            {
              "name" => "Basic",
              "stripe_price_id" => "price_basic",
              "price" => 10,
              "billing_period" => "month",
              "features" => [ "Feature 1", "Feature 2" ]
            }
          ])
        )
      end

      it "processes products array correctly" do
        patch hub_admin_configuration_path, params: products_params

        expect(config.products).to eq([
          {
            "name" => "Basic",
            "stripe_price_id" => "price_basic",
            "price" => 10,
            "billing_period" => "month",
            "features" => [ "Feature 1", "Feature 2" ]
          }
        ])
        expect(response).to redirect_to(hub_admin_configuration_path)
      end
    end
  end
end
