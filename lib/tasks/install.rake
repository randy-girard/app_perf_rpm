namespace :app_perf do
  desc "Install app_perf_ruby_agent.yml file"
  task :install do
    load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "install.rb"))
  end
end