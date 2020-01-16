require 'logger'
require 'rubygems'

begin
  require 'rails'

  case Rails.version
  when /^6/
    # Not loading sprockets
    # sprockets/railtie
    
    %w(
      active_record/railtie
      active_storage/engine
      action_controller/railtie
      action_view/railtie
      action_mailer/railtie
      active_job/railtie
      action_cable/engine
      action_mailbox/engine
      action_text/engine
      rails/test_unit/railtie
    ).each do |railtie|
      begin
        require railtie
      rescue LoadError
      end
    end
    require 'support/apps/rails6'
  when /^5/
    require "rails/all"
    require 'support/apps/rails5'
  when /^4/
    require "rails/all"
    require 'support/apps/rails4'
  when /^3/
    require "rails/all"
    require 'support/apps/rails3'
  else
    logger.error 'No rails version found.'
  end
rescue LoadError
  require "rails/all"
  require 'support/apps/rails2'
end
