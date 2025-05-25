require 'rails_helper'

RSpec.describe "Pricings", type: :request do
  describe "GET /pricing" do
    it "returns http success" do
      get pricing_path
      expect(response).to have_http_status(:success)
    end
  end
end
