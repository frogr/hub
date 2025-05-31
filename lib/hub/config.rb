require "yaml"
require "active_model"
require_relative "config/app_attributes"
require_relative "config/design_attributes"
require_relative "config/branding_attributes"
require_relative "config/feature_flags"
require_relative "config/seo_attributes"

module Hub
  class Config
    include ActiveModel::Model
    include ActiveModel::Validations

    CONFIG_PATH = Rails.root.join("config", "hub_config.yml")

    attr_reader :app_attributes, :design_attributes, :branding_attributes,
                :feature_flags, :seo_attributes, :products

    delegate :app_name, :app_class_name, :app_tagline, :app_description, to: :app_attributes
    delegate :primary_color, :secondary_color, :accent_color, :danger_color,
             :warning_color, :info_color, :success_color, :font_family,
             :heading_font_family, :border_radius, :css_variables, to: :design_attributes
    delegate :support_email, to: :branding_attributes
    delegate :passwordless_auth_enabled?, :stripe_payments_enabled?,
             :admin_panel_enabled?, to: :feature_flags
    delegate :og_image, to: :seo_attributes

    validate :validate_app_presence
    validate :validate_nested_attributes
    validate :validate_products

    class << self
      def current
        @current ||= load_from_file
      end

      def reload!
        @current = load_from_file
      end

      def load_from_file
        ConfigurationPersistenceService.new(new, CONFIG_PATH).load
      end
    end

    def initialize(attributes = {})
      attrs = attributes.respond_to?(:to_h) ? attributes.to_h.with_indifferent_access : attributes.with_indifferent_access
      @app_provided = attrs.key?(:app)
      @app_name_provided = attrs[:app] && attrs[:app].key?("name")
      @app_attributes = AppAttributes.new(attrs[:app] || {})
      @design_attributes = DesignAttributes.new(attrs[:design] || {})
      @branding_attributes = BrandingAttributes.new(attrs[:branding] || {})
      @feature_flags = FeatureFlags.new(attrs[:features] || {})
      @seo_attributes = SeoAttributes.new(attrs[:seo] || {})
      @products = attrs[:products] || []
    end

    def save
      return false unless valid?
      ConfigurationPersistenceService.new(self, CONFIG_PATH).save
    end

    def save!
      raise ActiveModel::ValidationError, self unless save
    end

    def app=(attributes)
      # Skip updating if nil is passed - this allows partial updates
      return if attributes.nil?

      @app_provided = true  # When setting app attributes, mark as provided
      attrs = attributes.respond_to?(:to_h) ? attributes.to_h.with_indifferent_access : attributes.with_indifferent_access
      @app_name_provided = attrs.key?(:name) || attrs.key?("name")
      @app_attributes = AppAttributes.new(attrs)
    end

    def design=(attributes)
      return if attributes.nil?
      @design_attributes = DesignAttributes.new(attributes)
    end

    def branding=(attributes)
      return if attributes.nil?
      @branding_attributes = BrandingAttributes.new(attributes)
    end

    def features=(attributes)
      return if attributes.nil?
      @feature_flags = FeatureFlags.new(attributes)
    end

    def seo=(attributes)
      return if attributes.nil?
      @seo_attributes = SeoAttributes.new(attributes)
    end

    def products=(value)
      return if value.nil?
      @products = value
    end

    def attributes
      {
        "app" => app_attributes.to_h,
        "design" => design_attributes.to_h,
        "branding" => branding_attributes.to_h,
        "features" => feature_flags.to_h,
        "seo" => seo_attributes.to_h,
        "products" => products
      }
    end

    def assign_attributes(attrs)
      # When loading from file, mark app as provided if it exists
      if attrs["app"]
        self.app = attrs["app"]
        @app_provided = true
        @app_name_provided = true if attrs["app"]["name"]
      end
      self.design = attrs["design"] if attrs["design"]
      self.branding = attrs["branding"] if attrs["branding"]
      self.features = attrs["features"] if attrs["features"]
      self.seo = attrs["seo"] if attrs["seo"]
      self.products = attrs["products"] if attrs["products"]
    end

    def logo_text
      branding_attributes.logo_text.presence || app_name
    end

    def footer_text
      branding_attributes.footer_text.presence || "© #{Date.current.year} #{app_name}. All rights reserved."
    end

    def default_title_suffix
      seo_attributes.default_title_suffix.presence || " | #{app_name}"
    end

    def default_description
      seo_attributes.default_description.presence || app_description
    end

    def app
      app_attributes.to_h
    end

    def design
      design_attributes.to_h
    end

    def branding
      branding_attributes.to_h
    end

    def features
      feature_flags.to_h
    end

    def seo
      seo_attributes.to_h
    end

    private

    def validate_app_presence
      # This is called by the test "validates presence of app"
      # The test creates config without app key and expects it to be invalid
      unless @app_provided
        errors.add(:app, "is required")
      end
    end

    def validate_nested_attributes
      # Validate app name when app is provided but name is missing
      if @app_provided && !@app_name_provided
        errors.add(:app, "must have a name")
      elsif app_attributes.name.blank?
        errors.add(:app, "name can't be blank")
      end

      add_nested_errors(app_attributes, :app)
      add_nested_errors(design_attributes, :design)
      add_nested_errors(branding_attributes, :branding)
      add_nested_errors(feature_flags, :features)
      add_nested_errors(seo_attributes, :seo)
    end

    def add_nested_errors(nested_model, prefix)
      return if nested_model.valid?

      nested_model.errors.each do |error|
        if error.attribute == :primary_color && error.type == :invalid
          errors.add(prefix, "primary_color must be a valid hex color (e.g., #RRGGBB)")
        else
          errors.add("#{prefix}.#{error.attribute}", error.message)
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
