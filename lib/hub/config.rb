module Hub
  class Config
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    CONFIG_PATH = Rails.root.join("config", "hub_config.yml")
    
    # Direct attributes instead of nested classes
    attribute :app_name, :string, default: "Hub"
    attribute :app_class_name, :string
    attribute :tagline, :string, default: "Ship faster"
    attribute :description, :string, default: "Rails SaaS starter"
    
    attribute :logo_text, :string
    attribute :footer_text, :string
    attribute :support_email, :string, default: "support@example.com"
    
    attribute :primary_color, :string, default: "#3B82F6"
    attribute :secondary_color, :string, default: "#10B981"
    attribute :accent_color, :string, default: "#F59E0B"
    attribute :danger_color, :string, default: "#EF4444"
    attribute :warning_color, :string, default: "#F59E0B"
    attribute :info_color, :string, default: "#3B82F6"
    attribute :success_color, :string, default: "#10B981"
    
    attribute :font_family, :string, default: "Inter"
    attribute :heading_font_family, :string
    attribute :border_radius, :string, default: "0.375rem"
    
    attribute :passwordless_auth, :boolean, default: true
    attribute :stripe_payments, :boolean, default: true
    attribute :admin_panel, :boolean, default: true
    
    attribute :products, default: []
    
    validates :app_name, presence: true
    validates :support_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates_format_of :primary_color, :secondary_color, :accent_color, 
                       :danger_color, :warning_color, :info_color, :success_color,
                       with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true

    class << self
      def current
        @current ||= load_from_file
      end

      def reload!
        @current = load_from_file
      end
      
      def load_from_file
        return new unless File.exist?(CONFIG_PATH)
        new(YAML.load_file(CONFIG_PATH))
      end
    end

    def save
      File.write(CONFIG_PATH, attributes.to_yaml) if valid?
    end

    def apply_changes!
      save && Generator.new(self).generate!
    end

    # Computed properties
    def app_class_name
      super.presence || app_name.gsub(/[^a-zA-Z0-9]/, '')
    end

    def heading_font_family
      super.presence || font_family
    end

    def logo_text
      super.presence || app_name
    end

    def footer_text
      super.presence || "© #{Date.current.year} #{app_name}. All rights reserved."
    end

    # CSS Variables
    def css_variables
      {
        "--color-primary" => primary_color,
        "--color-secondary" => secondary_color,
        "--color-accent" => accent_color,
        "--color-danger" => danger_color,
        "--color-warning" => warning_color,
        "--color-info" => info_color,
        "--color-success" => success_color,
        "--font-family" => font_family,
        "--font-family-heading" => heading_font_family,
        "--border-radius" => border_radius
      }
    end

    def color_variables
      css_variables.select { |k, _| k.include?("color") }
    end

    def font_variables
      css_variables.select { |k, _| k.include?("font") }
    end

    def as_json(options = {})
      attributes.merge(
        "app_class_name" => app_class_name,
        "logo_text" => logo_text,
        "footer_text" => footer_text,
        "heading_font_family" => heading_font_family,
        "css_variables" => css_variables
      )
    end
  end
end