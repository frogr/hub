# frozen_string_literal: true

module Config
  class Font
    SYSTEM_FONTS = [
      "system-ui",
      "-apple-system",
      "BlinkMacSystemFont",
      "Segoe UI",
      "Roboto",
      "Helvetica Neue",
      "Arial",
      "sans-serif"
    ].freeze

    GOOGLE_FONTS = %w[
      Inter
      Roboto
      Open\ Sans
      Lato
      Montserrat
      Raleway
      Poppins
      Source\ Sans\ Pro
      Playfair\ Display
      Merriweather
    ].freeze

    attr_reader :value

    def initialize(value)
      @value = value&.to_s&.strip
    end

    def system?
      @value.nil? || @value.empty? || SYSTEM_FONTS.include?(@value)
    end

    def google?
      GOOGLE_FONTS.include?(@value&.gsub("\\", ""))
    end

    def custom?
      !system? && !google?
    end

    def to_css
      return system_stack if system?
      return %("#{@value}", #{system_stack}) if google? || custom?

      system_stack
    end

    def to_s
      @value || ""
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      value == other.value
    end

    private

    def system_stack
      SYSTEM_FONTS.join(", ")
    end
  end
end
