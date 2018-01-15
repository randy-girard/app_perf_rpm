require 'logger'
require 'rubygems'

begin
  require 'rails'

  case Rails.version
  when /^5/
    require 'support/apps/rails5'
  when /^4/
    require 'support/apps/rails4'
  when /^3/
    require 'support/apps/rails3'
  else
    logger.error 'No rails version found.'
  end
rescue LoadError
  require 'support/apps/rails2'
end
