class TestsController < ActionController::Base
  include Rails.application.routes.url_helpers

  prepend_view_path File.join("spec", "views")

  def index
  end
end
