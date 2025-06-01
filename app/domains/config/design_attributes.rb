# frozen_string_literal: true

module Config
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

    validate :validate_colors
    validate :validate_fonts

    def primary_color_object
      @primary_color_object ||= Color.new(primary_color)
    end

    def secondary_color_object
      @secondary_color_object ||= Color.new(secondary_color)
    end

    def accent_color_object
      @accent_color_object ||= Color.new(accent_color)
    end

    def danger_color_object
      @danger_color_object ||= Color.new(danger_color)
    end

    def warning_color_object
      @warning_color_object ||= Color.new(warning_color)
    end

    def info_color_object
      @info_color_object ||= Color.new(info_color)
    end

    def success_color_object
      @success_color_object ||= Color.new(success_color)
    end

    def font_family_object
      @font_family_object ||= Font.new(font_family)
    end

    def heading_font_family_object
      @heading_font_family_object ||= Font.new(heading_font_family)
    end

    def heading_font_family
      super.presence || font_family
    end

    def to_h
      attributes
    end

    def css_variables
      {
        "--color-primary" => primary_color_object.to_css,
        "--color-secondary" => secondary_color_object.to_css,
        "--color-accent" => accent_color_object.to_css,
        "--color-danger" => danger_color_object.to_css,
        "--color-warning" => warning_color_object.to_css,
        "--color-info" => info_color_object.to_css,
        "--color-success" => success_color_object.to_css,
        "--font-family" => font_family_object.to_css,
        "--font-family-heading" => heading_font_family_object.to_css,
        "--border-radius" => border_radius
      }
    end

    private

    def validate_colors
      color_attributes = {
        primary_color: primary_color_object,
        secondary_color: secondary_color_object,
        accent_color: accent_color_object,
        danger_color: danger_color_object,
        warning_color: warning_color_object,
        info_color: info_color_object,
        success_color: success_color_object
      }

      color_attributes.each do |attr, color_obj|
        next if send(attr).blank?
        unless color_obj.valid?
          errors.add(attr, "must be a valid hex color (e.g., #RRGGBB)")
        end
      end
    end

    def validate_fonts
      # Fonts are always valid for now
    end
  end
end
