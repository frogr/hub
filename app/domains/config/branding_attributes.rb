# frozen_string_literal: true

module Config
  class BrandingAttributes
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :logo_text, :string
    attribute :footer_text, :string
    attribute :support_email, :string, default: "support@example.com"

    validates :support_email, format: { with: URI::MailTo::EMAIL_REGEXP },
                              allow_blank: true

    def support_email_object
      @support_email_object ||= Email.new(support_email)
    end

    def valid_support_email?
      support_email_object.valid?
    end

    def to_h
      attributes
    end
  end
end
