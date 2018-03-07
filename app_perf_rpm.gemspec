#-*- coding: utf-8 -*-
$:.push "#{File.expand_path('..', __FILE__)}/lib"

Gem::Specification.new do |s|
  s.name          = 'app_perf_rpm'
  s.version       = '0.2.4'
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
  s.add_runtime_dependency "opentracing"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "simplecov"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency "appraisal"
  s.add_development_dependency "wwtd"
end
