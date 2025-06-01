# frozen_string_literal: true

module Config
  class Email
    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

    attr_reader :value

    def initialize(value)
      @value = value&.to_s&.strip&.downcase
    end

    def valid?
      return false if @value.nil? || @value.empty?

      @value.match?(EMAIL_REGEX)
    end

    def domain
      return nil unless valid?

      @value.split("@").last
    end

    def local_part
      return nil unless valid?

      @value.split("@").first
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
