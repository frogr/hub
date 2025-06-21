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
          app_name: "MyApp",
          app_class_name: "MyApp",
          tagline: "New tagline",
          logo_text: "MyApp",
          support_email: "support@myapp.com",
          primary_color: "#FF0000",
          passwordless_auth: "1"
        }
      }
    end

    context "with valid parameters" do
      let(:config) do
        Hub::Config.new(
          app_name: "Hub",
          app_class_name: "Hub",
          tagline: "Ship faster",
          description: "Rails SaaS starter",
          primary_color: "#FF0000",
          secondary_color: "#10B981",
          accent_color: "#F59E0B",
          logo_text: "Hub",
          support_email: "support@example.com",
          passwordless_auth: true,
          stripe_payments: true,
          admin_panel: true,
          products: []
        )
      end

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)
        allow(config).to receive(:valid?).and_return(true)
        allow(config).to receive(:save).and_return(true)
        allow(config).to receive(:apply_changes!).and_return(true)
        # Allow setting attributes
        allow(config).to receive(:app_name=)
        allow(config).to receive(:app_class_name=)
        allow(config).to receive(:tagline=)
        allow(config).to receive(:logo_text=)
        allow(config).to receive(:support_email=)
        allow(config).to receive(:primary_color=)
        allow(config).to receive(:passwordless_auth=)
        allow(config).to receive(:products=)
      end

      it "updates the configuration" do
        patch hub_admin_configuration_path, params: valid_params

        expect(response).to redirect_to(hub_admin_configuration_path)
        expect(flash[:notice]).to be_present
      end

      it "displays success message without applying changes" do
        patch hub_admin_configuration_path, params: valid_params

        expect(flash[:notice]).to include("Configuration saved")
        expect(flash[:notice]).to include("Apply Changes")
      end

      context "when apply_changes is true" do
        it "runs the generator" do
          expect(config).to receive(:apply_changes!).and_return(true)

          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(flash[:notice]).to include("changes applied successfully")
        end

        it "handles generator failure" do
          expect(config).to receive(:apply_changes!).and_return(false)

          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(flash[:notice]).to include("changes applied successfully")
          expect(response).to redirect_to(hub_admin_configuration_path)
        end
      end
    end

    context "with invalid parameters" do
      let(:config) do
        Hub::Config.new(
          app_name: "Hub",
          app_class_name: "Hub",
          tagline: "Ship faster",
          description: "Rails SaaS starter",
          primary_color: "#FF0000",
          secondary_color: "#10B981",
          accent_color: "#F59E0B",
          logo_text: "Hub",
          support_email: "support@example.com",
          passwordless_auth: true,
          stripe_payments: true,
          admin_panel: true,
          products: []
        )
      end
      let(:invalid_params) do
        {
          config: {
            app_name: ""  # Invalid - name can't be blank
          }
        }
      end

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(Hub::Config).to receive(:reload!)
        allow(config).to receive(:app_name=).with("")
        allow(config).to receive(:valid?).and_return(false)
        allow(config).to receive(:errors).and_return(
          double(full_messages: [ "App name can't be blank" ], any?: true)
        )
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
          app_name: "Hub",
          app_class_name: "Hub",
          tagline: "Ship faster",
          description: "Rails SaaS starter",
          primary_color: "#FF0000",
          secondary_color: "#10B981",
          accent_color: "#F59E0B",
          logo_text: "Hub",
          support_email: "support@example.com",
          passwordless_auth: true,
          stripe_payments: true,
          admin_panel: true,
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
        # Config saves directly now, no need to mock a service
        allow(config).to receive(:valid?).and_return(true)
        allow(config).to receive(:save).and_return(true)
        allow(config).to receive(:products=)
      end

      it "processes products array correctly" do
        expected_products = [
          {
            "features" => "Feature 1\nFeature 2",
            "name" => "Basic",
            "price" => "10",
            "stripe_price_id" => "price_basic"
          },
          {
            "name" => "",
            "price" => "",
            "stripe_price_id" => ""
          }
        ]

        expect(config).to receive(:products=).with(expected_products)

        patch hub_admin_configuration_path, params: products_params

        expect(response).to redirect_to(hub_admin_configuration_path)
      end
    end
  end
end
