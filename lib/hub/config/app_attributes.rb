module Hub
  class Config
    class AppAttributes
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string, default: "Hub"
      attribute :class_name, :string
      attribute :tagline, :string, default: "Ship your Rails app faster"
      attribute :description, :string, default: "The fastest way to launch your SaaS"

      validates :name, presence: true

      def app_name
        name
      end

      def class_name
        # If class_name attribute is provided, sanitize it; otherwise generate from name
        if attributes["class_name"].present?
          attributes["class_name"].to_s.gsub(/[^a-zA-Z0-9]/, "")
        else
          name.to_s.gsub(/[^a-zA-Z0-9]/, "")
        end
      end

      def app_class_name
        class_name
      end

      def app_tagline
        tagline
      end

      def app_description
        description
      end

      def to_h
        attributes
      end
    end
  end
end
