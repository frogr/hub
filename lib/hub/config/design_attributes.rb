module Hub
  class Config
    class DesignAttributes
      include ActiveModel::Model
      include ActiveModel::Attributes

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

      validates :primary_color, :secondary_color, :accent_color, :danger_color,
                :warning_color, :info_color, :success_color,
                format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color (e.g., #RRGGBB)" },
                allow_blank: true

      def heading_font_family
        super.presence || font_family
      end

      def to_h
        attributes
      end

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
    end
  end
end
