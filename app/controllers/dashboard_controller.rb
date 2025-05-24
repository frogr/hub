class DashboardController < ApplicationController
  def index
    if user_signed_in?
      render :authenticated
    else
      render :public
    end
  end
end
