require "yaml"
require "active_model"

module Hub
  class Config
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    CONFIG_PATH = Rails.root.join("config", "hub_config.yml")

    # App attributes
    attribute :app, default: {}
    attribute :branding, default: {}
    attribute :products, default: []
    attribute :design, default: {}
    attribute :features, default: {}
    attribute :seo, default: {}

    # Validations
    validates :app, presence: true
    validate :validate_app_attributes
    validate :validate_design_attributes
    validate :validate_products

    class << self
      def current
        @current ||= load_from_file
      end

      def reload!
        @current = load_from_file
      end

      def load_from_file
        if File.exist?(CONFIG_PATH)
          config_data = YAML.load_file(CONFIG_PATH)
          new(config_data)
        else
          new
        end
      end
    end

    def initialize(attributes = {})
      super
      @original_attributes = attributes.deep_dup
    end

    def save
      return false unless valid?

      File.write(CONFIG_PATH, to_yaml)
      self.class.reload!
      true
    end

    def save!
      raise ActiveModel::ValidationError, self unless save
    end

    def to_yaml
      attributes.deep_stringify_keys.to_yaml
    end

    # Helper methods
    def app_name
      app["name"] || "Hub"
    end

    def app_class_name
      (app["class_name"] || app_name).gsub(/[^a-zA-Z0-9]/, "")
    end

    def app_tagline
      app["tagline"] || "Ship your Rails app faster"
    end

    def app_description
      app["description"] || "The fastest way to launch your SaaS"
    end

    def primary_color
      design["primary_color"] || "#3B82F6"
    end

    def secondary_color
      design["secondary_color"] || "#10B981"
    end

    def accent_color
      design["accent_color"] || "#F59E0B"
    end

    def danger_color
      design["danger_color"] || "#EF4444"
    end

    def warning_color
      design["warning_color"] || "#F59E0B"
    end

    def info_color
      design["info_color"] || "#3B82F6"
    end

    def success_color
      design["success_color"] || "#10B981"
    end

    def font_family
      design["font_family"] || "Inter"
    end

    def heading_font_family
      design["heading_font_family"] || font_family
    end

    def border_radius
      design["border_radius"] || "0.375rem"
    end

    def css_variables
      {
        "--color-primary": primary_color,
        "--color-secondary": secondary_color,
        "--color-accent": accent_color,
        "--color-danger": danger_color,
        "--color-warning": warning_color,
        "--color-info": info_color,
        "--color-success": success_color,
        "--font-family": font_family,
        "--font-family-heading": heading_font_family,
        "--border-radius": border_radius
      }
    end

    def passwordless_auth_enabled?
      features["passwordless_auth"] != false
    end

    def stripe_payments_enabled?
      features["stripe_payments"] != false
    end

    def admin_panel_enabled?
      features["admin_panel"] != false
    end

    def logo_text
      branding["logo_text"] || app_name
    end

    def footer_text
      branding["footer_text"] || "© #{Date.current.year} #{app_name}. All rights reserved."
    end

    def support_email
      branding["support_email"] || "support@example.com"
    end

    def default_title_suffix
      seo["default_title_suffix"] || " | #{app_name}"
    end

    def default_description
      seo["default_description"] || app_description
    end

    def og_image
      seo["og_image"] || "/og-image.png"
    end

    private

    def validate_app_attributes
      return if app.blank?

      errors.add(:app, "must have a name") if app["name"].blank?
    end

    def validate_design_attributes
      return if design.blank?

      # Validate color formats
      color_keys = %w[primary_color secondary_color accent_color danger_color warning_color info_color success_color]
      color_keys.each do |key|
        next if design[key].blank?
        unless design[key].match?(/\A#[0-9A-Fa-f]{6}\z/)
          errors.add(:design, "#{key} must be a valid hex color (e.g., #RRGGBB)")
        end
      end
    end

    def validate_products
      return if products.blank?

      products.each_with_index do |product, index|
        if product["name"].blank?
          errors.add(:products, "product at index #{index} must have a name")
        end
        if product["price"].blank? || !product["price"].is_a?(Numeric)
          errors.add(:products, "product at index #{index} must have a numeric price")
        end
      end
    end
  end
end
