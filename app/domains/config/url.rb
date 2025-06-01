# frozen_string_literal: true

module Config
  class Url
    attr_reader :value

    def initialize(value)
      @value = value&.to_s&.strip
    end

    def valid?
      return false if @value.nil? || @value.empty?

      uri = URI.parse(@value)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end

    def scheme
      return nil unless valid?

      URI.parse(@value).scheme
    end

    def host
      return nil unless valid?

      URI.parse(@value).host
    end

    def path
      return nil unless valid?

      parsed_path = URI.parse(@value).path
      parsed_path.empty? ? "/" : parsed_path
    end

    def to_s
      @value || ""
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      value == other.value
    end
  end
end
