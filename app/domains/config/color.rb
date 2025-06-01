# frozen_string_literal: true

module Config
  class Color
    HEX_COLOR_REGEX = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
    NAMED_COLORS = %w[
      black white red green blue yellow purple orange gray
      primary secondary accent danger warning info success
    ].freeze

    attr_reader :value

    def initialize(value)
      @value = normalize_color(value)
    end

    def hex?
      @value&.match?(HEX_COLOR_REGEX)
    end

    def named?
      NAMED_COLORS.include?(@value)
    end

    def valid?
      hex? || named? || css_var?
    end

    def css_var?
      @value&.start_with?("var(--") && @value&.end_with?(")")
    end

    def to_s
      @value || ""
    end

    def to_css
      return @value if hex? || css_var?
      return "var(--#{@value})" if named? && !standard_color?

      # For standard colors, return the actual color value
      case @value
      when "black" then "#000000"
      when "white" then "#FFFFFF"
      when "red" then "#FF0000"
      when "green" then "#00FF00"
      when "blue" then "#0000FF"
      when "yellow" then "#FFFF00"
      when "purple" then "#800080"
      when "orange" then "#FFA500"
      when "gray" then "#808080"
      else
        @value
      end
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      value == other.value
    end

    private

    def normalize_color(value)
      return nil if value.nil?

      str = value.to_s.strip.downcase
      return str.upcase if str.match?(HEX_COLOR_REGEX)

      str
    end

    def standard_color?
      %w[black white red green blue yellow purple orange gray].include?(@value)
    end
  end
end
