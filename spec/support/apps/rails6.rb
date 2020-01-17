require 'support/apps/base_application'

module Rails6
  class Application < AppPerfRpm::TestRailsApp
  end
end

Rails.application.routes.append do
  resources :tests, :only => [:index]
end

Rails6::Application.do_initialization!
