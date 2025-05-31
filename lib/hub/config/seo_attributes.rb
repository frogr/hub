module Hub
  class Config
    class SeoAttributes
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :default_title_suffix, :string
      attribute :default_description, :string
      attribute :og_image, :string, default: "/og-image.png"

      def to_h
        attributes
      end
    end
  end
end
