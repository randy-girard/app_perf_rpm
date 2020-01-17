# AppPerf Ruby Agent

[![Build Status](https://travis-ci.org/randy-girard/app_perf_rpm.svg?branch=master)](https://travis-ci.org/randy-girard/app_perf_rpm)

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

## Running tests

Make sure `appraisal` is up to date:

```
bundle exec appraisal install
```

Then switch to your specific ruby version and run a specific appraisal:

```
rvm use 2.1.2
bundle exec appraisal rails-3.0 rake spec
```

If you want to run all ruby versions and all appraisals,
Make sure the `wwtd` gem is installed and run:

```
wwtd
```

Consult the `.travis.yml` file for up-to-date ruby versions and framework versions supported.
