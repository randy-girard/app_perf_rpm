# AppPerf Ruby Agent

Ruby Agent for the AppPerf app

https://www.github.com/randy-girard/app_perf

## How to use

It is recommended you DO not run this in `test` environments.

```
group :development, :production do 
  gem "app_perf_rpm", :git => "https://github.com/randy-girard/app_perf_rpm", :branch => "master"
end
```


After adding gem to your project and then navigate to the AppPerf app, go to the applications page and click the New Application button. Follow the directions.
