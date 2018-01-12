#-*- coding: utf-8 -*-
$:.push "#{File.expand_path('..', __FILE__)}/lib"

Gem::Specification.new do |s|
  s.name          = 'app_perf_rpm'
  s.version       = '0.2.0'
  s.date          = '2016-05-16'
  s.summary       = "AppPerf Ruby Agent"
  s.description   = "Ruby Agent for the AppPerf app."
  s.authors       = ["Randy Girard"]
  s.email         = "rgirard59@yahoo.com"

  s.files         = Dir["{exe,lib}/**/*"]

  s.bindir        = 'exe'
  s.executables   = `git ls-files -- exe/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]
  s.homepage      = 'https://www.github.com/randy-girard/app_perf_rpm'
  s.license       = 'MIT'

  s.add_runtime_dependency "msgpack"
  s.add_runtime_dependency "opentracing", "0.3.1"

  s.add_development_dependency "rake", "12.0.0"
  s.add_development_dependency "rspec", "3.5.0"
  s.add_development_dependency "pry", "0.10.4"
  s.add_development_dependency "simplecov", "0.12.0"
  s.add_development_dependency "rails"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'actionpack'
  s.add_development_dependency 'activesupport'
end
