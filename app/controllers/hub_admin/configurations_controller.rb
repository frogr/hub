class HubAdmin::ConfigurationsController < HubAdmin::BaseController
  def show
    @config = Hub::Config.current
  end

  def update
    @config = Hub::Config.current

    # Update config attributes
    @config.app = config_params[:app] if config_params[:app].present?
    @config.branding = config_params[:branding] if config_params[:branding].present?
    @config.design = config_params[:design] if config_params[:design].present?
    @config.features = config_params[:features] if config_params[:features].present?
    @config.seo = config_params[:seo] if config_params[:seo].present?

    # Handle products separately to manage arrays properly
    if params[:products].present?
      @config.products = build_products_array
    end

    if @config.save
      # Run the generator to apply changes
      if params[:apply_changes] == "true"
        success = Hub::Generator.run!
        if success
          redirect_to hub_admin_configuration_path, notice: "Configuration updated and changes applied successfully!"
        else
          redirect_to hub_admin_configuration_path, alert: "Configuration saved but failed to apply changes. Check the logs."
        end
      else
        redirect_to hub_admin_configuration_path, notice: "Configuration saved. Click 'Apply Changes' to regenerate your app."
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def config_params
    params.require(:config).permit(
      app: [ :name, :class_name, :tagline, :description ],
      branding: [ :logo_text, :footer_text, :support_email ],
      design: [ :primary_color, :secondary_color, :accent_color, :danger_color,
               :warning_color, :info_color, :success_color, :font_family,
               :heading_font_family, :border_radius ],
      features: [ :passwordless_auth, :stripe_payments, :admin_panel ],
      seo: [ :default_title_suffix, :default_description, :og_image ]
    )
  end

  def build_products_array
    products = []
    params[:products].each do |index, product_params|
      next if product_params[:name].blank?

      products << {
        "name" => product_params[:name],
        "stripe_price_id" => product_params[:stripe_price_id],
        "price" => product_params[:price].to_i,
        "billing_period" => product_params[:billing_period] || "month",
        "features" => (product_params[:features] || "").split("\n").map(&:strip).reject(&:blank?)
      }
    end
    products
  end
end
