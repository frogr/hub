require "rails_helper"

RSpec.describe ProductsBuilderService do
  let(:products_params) do
    {
      "0" => {
        name: "Basic Plan",
        price: "19",
        stripe_price_id: "price_basic",
        billing_period: "month",
        features: "Feature 1\nFeature 2\nFeature 3"
      },
      "1" => {
        name: "Pro Plan",
        price: "49",
        stripe_price_id: "price_pro",
        billing_period: "month",
        features: "All Basic features\nPro Feature 1\nPro Feature 2"
      }
    }
  end
  let(:service) { described_class.new(products_params) }

  describe "#build" do
    context "with valid product params" do
      it "builds array of products" do
        result = service.build

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
      end

      it "converts product data correctly" do
        result = service.build

        expect(result[0]).to eq({
          "name" => "Basic Plan",
          "stripe_price_id" => "price_basic",
          "price" => 19,
          "billing_period" => "month",
          "features" => [ "Feature 1", "Feature 2", "Feature 3" ]
        })

        expect(result[1]).to eq({
          "name" => "Pro Plan",
          "stripe_price_id" => "price_pro",
          "price" => 49,
          "billing_period" => "month",
          "features" => [ "All Basic features", "Pro Feature 1", "Pro Feature 2" ]
        })
      end
    end

    context "with empty params" do
      let(:products_params) { {} }

      it "returns empty array" do
        expect(service.build).to eq([])
      end
    end

    context "with nil params" do
      let(:products_params) { nil }

      it "returns empty array" do
        expect(service.build).to eq([])
      end
    end

    context "with products missing names" do
      let(:products_params) do
        {
          "0" => { name: "", price: "10" },
          "1" => { name: "Valid", price: "20" },
          "2" => { name: nil, price: "30" }
        }
      end

      it "filters out products without names" do
        result = service.build

        expect(result.length).to eq(1)
        expect(result[0]["name"]).to eq("Valid")
      end
    end

    context "with missing or invalid prices" do
      let(:products_params) do
        {
          "0" => { name: "Free", price: "" },
          "1" => { name: "Paid", price: "invalid" },
          "2" => { name: "Premium", price: nil }
        }
      end

      it "sets price to 0 for invalid values" do
        result = service.build

        expect(result[0]["price"]).to eq(0)
        expect(result[1]["price"]).to eq(0)
        expect(result[2]["price"]).to eq(0)
      end
    end

    context "with missing billing period" do
      let(:products_params) do
        {
          "0" => { name: "Test", price: "10", billing_period: nil }
        }
      end

      it "defaults to month" do
        result = service.build
        expect(result[0]["billing_period"]).to eq("month")
      end
    end

    context "with various feature formats" do
      let(:products_params) do
        {
          "0" => { name: "Test1", price: "10", features: "" },
          "1" => { name: "Test2", price: "20", features: nil },
          "2" => { name: "Test3", price: "30", features: "Single feature" },
          "3" => { name: "Test4", price: "40", features: "\n\nFeature 1\n\nFeature 2\n\n" }
        }
      end

      it "handles empty features" do
        result = service.build

        expect(result[0]["features"]).to eq([])
        expect(result[1]["features"]).to eq([])
      end

      it "handles single feature" do
        result = service.build
        expect(result[2]["features"]).to eq([ "Single feature" ])
      end

      it "filters blank lines from features" do
        result = service.build
        expect(result[3]["features"]).to eq([ "Feature 1", "Feature 2" ])
      end
    end
  end

  describe "#extract_price" do
    it "converts string to integer" do
      expect(service.send(:extract_price, "100")).to eq(100)
    end

    it "returns 0 for blank values" do
      expect(service.send(:extract_price, "")).to eq(0)
      expect(service.send(:extract_price, nil)).to eq(0)
    end

    it "converts non-numeric strings to 0" do
      expect(service.send(:extract_price, "abc")).to eq(0)
    end
  end

  describe "#extract_features" do
    it "splits features by newline" do
      features = service.send(:extract_features, "Feature 1\nFeature 2")
      expect(features).to eq([ "Feature 1", "Feature 2" ])
    end

    it "removes whitespace from features" do
      features = service.send(:extract_features, "  Feature 1  \n  Feature 2  ")
      expect(features).to eq([ "Feature 1", "Feature 2" ])
    end

    it "returns empty array for nil" do
      features = service.send(:extract_features, nil)
      expect(features).to eq([])
    end
  end
end
