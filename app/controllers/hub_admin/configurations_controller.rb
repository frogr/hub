class HubAdmin::ConfigurationsController < HubAdmin::BaseController
  def show
    @config = Hub::Config.current
  end

  def update
    @config = Hub::Config.current

    # Update config with flattened attributes
    if update_config_from_params
      handle_success
    else
      handle_failure
    end
  end

  private

  def update_params
    params.permit(:apply_changes).merge(
      config_attributes: config_params,
      products: products_params
    )
  end

  def config_params
    return {} unless params[:config].present?

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

  def update_config_from_params
    config_data = config_params

    # Flatten nested params to match new config structure
    if config_data[:app]
      @config.app_name = config_data[:app][:name] if config_data[:app][:name]
      @config.app_class_name = config_data[:app][:class_name] if config_data[:app][:class_name]
      @config.tagline = config_data[:app][:tagline] if config_data[:app][:tagline]
      @config.description = config_data[:app][:description] if config_data[:app][:description]
    end

    if config_data[:branding]
      @config.logo_text = config_data[:branding][:logo_text] if config_data[:branding][:logo_text]
      @config.footer_text = config_data[:branding][:footer_text] if config_data[:branding][:footer_text]
      @config.support_email = config_data[:branding][:support_email] if config_data[:branding][:support_email]
    end

    if config_data[:design]
      config_data[:design].each do |key, value|
        @config.send("#{key}=", value) if @config.respond_to?("#{key}=")
      end
    end

    if config_data[:features]
      @config.passwordless_auth = config_data[:features][:passwordless_auth] == "1" if config_data[:features][:passwordless_auth]
      @config.stripe_payments = config_data[:features][:stripe_payments] == "1" if config_data[:features][:stripe_payments]
      @config.admin_panel = config_data[:features][:admin_panel] == "1" if config_data[:features][:admin_panel]
    end

    # Handle products if provided
    if products_params.present?
      @config.products = products_params.values.map(&:to_h)
    end

    if @config.valid?
      @config.save
      @config.apply_changes! if params[:apply_changes] == "true"
      true
    else
      false
    end
  end

  def products_params
    return {} unless params[:products].present?

    # Dynamic permit for any number of products
    product_keys = params[:products].keys
    permitted_attributes = product_keys.to_h { |key| [ key, [ :name, :stripe_price_id, :price, :billing_period, :features ] ] }

    params.require(:products).permit(permitted_attributes)
  end

  def handle_success
    # Reload to ensure we have the latest saved config
    Hub::Config.reload!
    message = build_success_message
    redirect_to hub_admin_configuration_path, notice: message
  end

  def handle_failure
    flash.now[:alert] = @config.errors.full_messages.join(", ")
    render :show, status: :unprocessable_entity
  end

  def build_success_message
    if params[:apply_changes] == "true"
      "Configuration updated and changes applied successfully!"
    else
      "Configuration saved. Click 'Apply Changes' to regenerate your app."
    end
  end
end
