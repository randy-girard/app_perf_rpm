require 'support/apps/base_application'

module Rails5
  class Application < AppPerfRpm::TestRailsApp
  end
end

Rails.application.routes.append do
  resources :tests, :only => [:index]
end

Rails5::Application.do_initialization!
