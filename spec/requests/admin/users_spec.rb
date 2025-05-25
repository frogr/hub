require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let!(:admin_user) { create(:user, admin: true) }
  let!(:regular_user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "GET /admin/users" do
    it "returns http success for admin users" do
      sign_in admin_user
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "redirects non-admin users" do
      sign_in regular_user
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects non-authenticated users" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/users/:id" do
    it "returns http success for admin users" do
      sign_in admin_user
      get admin_user_path(other_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "returns http success for admin users" do
      sign_in admin_user
      get edit_admin_user_path(other_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates the user" do
      sign_in admin_user
      patch admin_user_path(other_user), params: { user: { email: "newemail@example.com" } }
      expect(response).to redirect_to(admin_user_path(other_user))
      expect(other_user.reload.email).to eq("newemail@example.com")
    end
  end
end
