module Hub
  class Config
    class BrandingAttributes
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :logo_text, :string
      attribute :footer_text, :string
      attribute :support_email, :string, default: "support@example.com"

      validates :support_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

      def to_h
        attributes
      end
    end
  end
end
