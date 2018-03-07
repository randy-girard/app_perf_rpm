class TestsController < ActionController::Base
  include Rails.application.routes.url_helpers

  prepend_view_path File.join("spec", "views")
  prepend_view_path File.join("spec", "layouts")

  layout "application"

  def index
  end
end
