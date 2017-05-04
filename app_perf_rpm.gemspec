#-*- coding: utf-8 -*-
$:.push "#{File.expand_path('..', __FILE__)}/lib"

Gem::Specification.new do |s|
  s.name          = 'app_perf_rpm'
  s.version       = '0.0.1'
  s.date          = '2016-05-16'
  s.summary       = "AppPerf Ruby Agent"
  s.description   = "Ruby Agent for the AppPerf app."
  s.authors       = ["Randy Girard"]
  s.email         = "rgirard59@yahoo.com"

  files  = `git ls-files`.split("\n") rescue []
  files += Dir['lib/**/*.rb']
  s.files         = files

  s.require_paths = ["lib"]
  s.homepage      = 'https://www.github.com/randy-girard/app_perf_rpm'
  s.license       = 'MIT'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "simplecov"
  s.add_runtime_dependency "oj"
  s.add_runtime_dependency "sys-cpu"
  s.add_runtime_dependency "sys-filesystem"
end
