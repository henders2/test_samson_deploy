# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "zendesk_deployment"
  s.version = "2.0.0.rc2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mick Staugaard", "David Nghiem"]
  s.date = "2014-12-19"
  s.description = "Our way of deploying apps"
  s.email = ["mick@staugaard.com"]
  s.files = ["lib/zendesk", "lib/zendesk/deployment", "lib/zendesk/deployment/airbrake.rb", "lib/zendesk/deployment/bundler.rb", "lib/zendesk/deployment/challenge.rb", "lib/zendesk/deployment/check_setup.rb", "lib/zendesk/deployment/code_changes.rb", "lib/zendesk/deployment/committish.rb", "lib/zendesk/deployment/deployer.rb", "lib/zendesk/deployment/environment_discovery.rb", "lib/zendesk/deployment/environment_selector.rb", "lib/zendesk/deployment/full_log.rb", "lib/zendesk/deployment/lock.rb", "lib/zendesk/deployment/log_upload.rb", "lib/zendesk/deployment/migrations.rb", "lib/zendesk/deployment/mirror_strategy.rb", "lib/zendesk/deployment/new_relic.rb", "lib/zendesk/deployment/notify.rb", "lib/zendesk/deployment/report_status.rb", "lib/zendesk/deployment/restart.rb", "lib/zendesk/deployment/ruby_version.rb", "lib/zendesk/deployment/show_hosts.rb", "lib/zendesk/deployment/tags.rb", "lib/zendesk/deployment/utils.rb", "lib/zendesk/deployment/version.rb", "lib/zendesk/deployment/warn_if_local.rb", "lib/zendesk/deployment.rb", "lib/zendesk_deployment.rb", "README.md"]
  s.homepage = ""
  s.licenses = ["All rights reserved"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.14"
  s.summary = "A collection of capistrano tasks"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>, ["< 3.0.0"])
      s.add_runtime_dependency(%q<deep_merge>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<bump>, [">= 0"])
      s.add_development_dependency(%q<timecop>, [">= 0"])
      s.add_development_dependency(%q<airbrake>, [">= 0"])
      s.add_development_dependency(%q<newrelic_rpm>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<minitest-rg>, [">= 0"])
      s.add_development_dependency(%q<minitest-around>, [">= 0"])
    else
      s.add_dependency(%q<capistrano>, ["< 3.0.0"])
      s.add_dependency(%q<deep_merge>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<bump>, [">= 0"])
      s.add_dependency(%q<timecop>, [">= 0"])
      s.add_dependency(%q<airbrake>, [">= 0"])
      s.add_dependency(%q<newrelic_rpm>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<minitest-rg>, [">= 0"])
      s.add_dependency(%q<minitest-around>, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>, ["< 3.0.0"])
    s.add_dependency(%q<deep_merge>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<bump>, [">= 0"])
    s.add_dependency(%q<timecop>, [">= 0"])
    s.add_dependency(%q<airbrake>, [">= 0"])
    s.add_dependency(%q<newrelic_rpm>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<minitest-rg>, [">= 0"])
    s.add_dependency(%q<minitest-around>, [">= 0"])
  end
end
