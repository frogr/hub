class HubAdmin::BaseController < ApplicationController
  before_action :authenticate_admin!

  private

  def authenticate_admin!
    redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
  end

  # Define current_user for testing purposes
  # In production, this is inherited from ApplicationController via Devise
  def current_user
    super if defined?(super)
  end
end
