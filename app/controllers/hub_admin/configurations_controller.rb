class HubAdmin::ConfigurationsController < HubAdmin::BaseController
  def show
    @config = Hub::Config.current
  end

  def update
    result = ConfigurationUpdateService.new(update_params, Hub::Config.current).execute

    if result.success?
      handle_success(result)
    else
      handle_failure(result)
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

  def products_params
    return {} unless params[:products].present?

    params.require(:products).permit!
  end

  def handle_success(result)
    # Reload to ensure we have the latest saved config
    Hub::Config.reload!
    message = build_success_message
    redirect_to hub_admin_configuration_path, notice: message
  end

  def handle_failure(result)
    # Force reload from file to ensure we have a valid config
    Hub::Config.reload!
    @config = Hub::Config.current
    flash.now[:alert] = result.errors.join(", ")
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
