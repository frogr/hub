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
      before { sign_in regular_user }

      it "redirects to root with alert" do
        get hub_admin_configuration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized")
      end
    end

    context "when authenticated as admin" do
      before { sign_in admin_user }

      it "displays the configuration form" do
        get hub_admin_configuration_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Hub Configuration")
      end

      it "loads current configuration" do
        config = Hub::Config.current
        allow(Hub::Config).to receive(:current).and_return(config)

        get hub_admin_configuration_path
        expect(assigns(:config)).to eq(config)
      end
    end
  end

  describe "PATCH /hub_admin/configuration" do
    before { sign_in admin_user }

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
      let(:config) { instance_double(Hub::Config, save: true) }

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
        allow(config).to receive(:app=)
        allow(config).to receive(:branding=)
        allow(config).to receive(:design=)
        allow(config).to receive(:features=)
        allow(config).to receive(:products=)
      end

      it "updates the configuration" do
        patch hub_admin_configuration_path, params: valid_params

        expect(config).to have_received(:app=).with(anything)
        expect(config).to have_received(:save)
        expect(response).to redirect_to(hub_admin_configuration_path)
      end

      it "displays success message without applying changes" do
        patch hub_admin_configuration_path, params: valid_params

        expect(flash[:notice]).to include("Configuration saved")
        expect(flash[:notice]).to include("Apply Changes")
      end

      context "when apply_changes is true" do
        before do
          allow(Hub::Generator).to receive(:run!).and_return(true)
        end

        it "runs the generator" do
          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(Hub::Generator).to have_received(:run!)
          expect(flash[:notice]).to include("changes applied successfully")
        end

        it "handles generator failure" do
          allow(Hub::Generator).to receive(:run!).and_return(false)

          patch hub_admin_configuration_path, params: valid_params.merge(apply_changes: "true")

          expect(flash[:alert]).to include("failed to apply changes")
        end
      end
    end

    context "with invalid parameters" do
      let(:config) do
        config_instance = Hub::Config.new
        allow(config_instance).to receive(:save).and_return(false)
        allow(config_instance).to receive(:errors).and_return(double(any?: true, full_messages: [ "Error" ]))
        config_instance
      end

      before do
        allow(Hub::Config).to receive(:current).and_return(config)
      end

      it "renders the form with errors" do
        patch hub_admin_configuration_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:config)).to eq(config)
      end
    end

    context "with products parameters" do
      let(:config) { instance_double(Hub::Config, save: true) }
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
        allow(config).to receive(:app=)
        allow(config).to receive(:branding=)
        allow(config).to receive(:design=)
        allow(config).to receive(:features=)
        allow(config).to receive(:products=)
      end

      it "processes products array correctly" do
        patch hub_admin_configuration_path, params: products_params

        expect(config).to have_received(:products=).with([
          {
            "name" => "Basic",
            "stripe_price_id" => "price_basic",
            "price" => 10,
            "billing_period" => "month",
            "features" => [ "Feature 1", "Feature 2" ]
          }
        ])
      end
    end
  end
end
