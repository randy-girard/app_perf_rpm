require 'support/apps/base_application'

# Rails 4.0 and 4.1 fix.
if Rails.version < "4.2"
  class << AppPerfRpm::TestRailsApp
    def inherited(base)
    end
  end
end

module Rails4
  class Application < AppPerfRpm::TestRailsApp
  end
end

if Rails.version < "4.2"
  Rails.application.routes.draw do
    resources :tests, :only => [:index]
  end
else
  Rails.application.routes.append do
    resources :tests, :only => [:index]
  end
end

Rails4::Application.do_initialization!
