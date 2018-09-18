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

## Naming metrics.

applications/frameworks/libraries

??? - rack

heirarchy

first part

app - application server
system - physical servers or vms
db - database servers running on machines
http - web servers running

second part

primary metric we are record

app.http (http requests within app)
db.mysql (mysql server)
http.nginx (nginx server)
server.memory (memory on server)

app.web.requests (rack, rails, sinatra, grape, etc))
Framework - rails, sinatra, roda, grape, emque_consuming, padrino

app.worker.requests (tag with sidekiq, delayed_job, etc)
Background processors - sidekiq, delayed_job, resque

app.db.requests (tag with component and driver)
db frameworks - active_record, sequel, activerecord_import
database drives - redis, memcache, mongo, pg, mysql, sqlite, etc

app.http.requests (tag with component)
http services - net_http, faraday, typhoeus

app.view.requests (tag with component)
view renderers - action_view

servers (physical, vm, kube, docker tags)
memory (system.memory.free, system.memory.used)
cpu (system.cpu.idle, etc)
diskspace (system.storage.free)

databases (server type)
db.mysql.??
db.pg....
database info ()

web servers
http.nginx.requests
http.apache.requests

metrics to record

count (count)
total (sum)
avg
histogram
mean
stddev
percentiles?

## Supported versions

Currently, AppPerf supports the following versions of frameworks and rubies:

- Rails 3.0.x, Ruby 2.1.2
- Rails 3.1.x, Ruby 2.1.2
- Rails 3.2.x, Ruby 2.1.2, 2.2.2
- Rails 4.0.x, Ruby 2.1.2, 2.2.2
- Rails 4.1.x, Ruby 2.1.2, 2.2.2
- Rails 4.2.x, Ruby 2.1.2, 2.2.2
- Rails 5.0.x, Ruby 2.2.2, 2.4.1, 2.5.0
- Rails 5.1.x, Ruby 2.2.2, 2.4.1, 2.5.0

Consult the `.travis.yml` file for up-to-date ruby versions and framework versions supported.
