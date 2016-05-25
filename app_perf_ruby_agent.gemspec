#-*- coding: utf-8 -*-
Gem::Specification.new do |s|
  s.name          = 'app_perf_ruby_agent'
  s.version       = '0.0.1'
  s.date          = '2016-05-16'
  s.summary       = "AppPerf Ruby Agent"
  s.description   = "Ruby Agent for the AppPerf app."
  s.authors       = ["Randy Girard"]
  s.email         = ""
  s.files         = `git ls-files`.split
  s.require_paths = ["lib"]
  s.homepage      = 'https://www.github.com/randy-girard/app_perf_ruby_agent'
  s.license       = 'MIT'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "rails"
end