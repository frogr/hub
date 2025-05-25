class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery with: :exception

  helper_method :user_has_access_to_feature?

  def after_sign_in_path_for(resource)
    dashboard_index_path
  end

  protected

  def require_subscription!(plan_names = nil)
    unless user_signed_in? && current_user.has_active_subscription?
      redirect_to pricing_path, alert: "You need an active subscription to access this feature."
      return
    end

    if plan_names.present?
      allowed_plans = Array(plan_names)
      unless allowed_plans.include?(current_user.current_plan&.name)
        redirect_to pricing_path, alert: "Your current plan doesn't include access to this feature. Please upgrade."
      end
    end
  end

  def user_has_access_to_feature?(feature_name)
    return false unless user_signed_in?

    case feature_name
    when :api_access
      current_user.subscribed_to?(Plan.find_by(name: "Pro")) ||
      current_user.subscribed_to?(Plan.find_by(name: "Elite"))
    when :custom_integrations
      current_user.subscribed_to?(Plan.find_by(name: "Pro")) ||
      current_user.subscribed_to?(Plan.find_by(name: "Elite"))
    when :enterprise_features
      current_user.subscribed_to?(Plan.find_by(name: "Elite"))
    when :advanced_analytics
      current_user.subscribed_to?(Plan.find_by(name: "Elite"))
    else
      current_user.has_active_subscription?
    end
  end
end
