require_relative 'helper'
require 'zendesk/deployment/new_relic'

describe Zendesk::Deployment::NewRelic do
  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::NewRelic)
  end

  it 'reads production license from /data/zendesk/config/newrelic.yml or /data/samson/config/newrelic.yml' do
    cap.production_newrelic_config.must_equal ['/data/zendesk/config/newrelic.yml', '/data/samson/config/newrelic.yml']
  end

  it 'reads appname from config/newrelic.yml' do
    cap.development_newrelic_config.must_include './config/newrelic.yml'
  end

  it 'reads appname from config/newrelic.yml.example' do
    cap.development_newrelic_config.must_include './config/newrelic.yml.example'
  end

  describe 'with no config files present' do
    before do
      cap.set(:development_newrelic_config, './test/newrelic_configs/development-not-fount.yml')
      cap.set(:production_newrelic_config,  './test/newrelic_configs/production-not-found.yml')
    end

    it 'reads appname from development_newrelic_config' do
      cap.newrelic_appname.must_be_nil
    end

    it 'reads license from production_newrelic_config' do
      cap.newrelic_license_key.must_be_nil
    end
  end

  describe 'with config files present' do
    before do
      cap.set(:development_newrelic_config, './test/newrelic_configs/development.yml')
      cap.set(:production_newrelic_config,  './test/newrelic_configs/production.yml')
    end

    it 'reads appname from development_newrelic_config' do
      cap.newrelic_appname.must_equal 'development_appname'
    end

    it 'reads license from production_newrelic_config' do
      cap.newrelic_license_key.must_equal 'production_license'
    end
  end

  it 'runs newrelic:notice_deployment on deploy' do
    cap.find_and_execute_task 'deploy'
    cap.must_have_invoked 'newrelic:notice_deployment'
  end

  # TODO
  #it 'runs newrelic:notice_deployment on deploy:switch' do
  #  cap.find_and_execute_task 'deploy:switch'
  #  cap.must_have_invoked 'newrelic:notice_deployment'
  #end
end
