class ProductsBuilderService
  attr_reader :products_params

  def initialize(products_params)
    @products_params = products_params || {}
  end

  def build
    return [] if products_params.empty?

    products_params.to_h.map do |index, product_data|
      build_product(product_data)
    end.compact
  end

  private

  def build_product(product_data)
    return nil if product_data[:name].blank?

    {
      "name" => product_data[:name],
      "stripe_price_id" => product_data[:stripe_price_id],
      "price" => extract_price(product_data[:price]),
      "billing_period" => product_data[:billing_period] || "month",
      "features" => extract_features(product_data[:features])
    }
  end

  def extract_price(price)
    return 0 if price.blank?
    price.to_i
  end

  def extract_features(features_string)
    return [] if features_string.blank?
    features_string.split("\n").map(&:strip).reject(&:blank?)
  end
end
