require 'devise'

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Ensure Warden is set up properly for tests
  config.include Warden::Test::Helpers

  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:each) do
    Warden.test_reset!
  end

  # Custom sign in helper for tests
  def sign_in_user(user)
    login_as(user, scope: :user)
  end

  # Make the custom helper available in request specs
  config.include Module.new {
    def sign_in(user)
      sign_in_user(user)
    end
  }, type: :request
end
