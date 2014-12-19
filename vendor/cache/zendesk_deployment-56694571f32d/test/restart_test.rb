require_relative 'helper'
require 'zendesk/deployment/restart'

describe Zendesk::Deployment::Restart do
  let(:exclude_services) { [] }
  let(:allow_check_services_failure) { false }

  before do
    cap.extend(Zendesk::Deployment::Restart)

    cap.set :application, 'test_app'
    cap.set :exclude_services, exclude_services if exclude_services.any?
    cap.set :allow_check_services_failure, allow_check_services_failure if allow_check_services_failure
  end

  describe 'deploy:restart' do
    before { cap.find_and_execute_task('deploy:restart') }

    it 'must use reload_services and check_services' do
      cap.must_have_run('sudo /usr/local/bin/reload_services test_app')
      cap.must_have_run('sudo /usr/local/bin/check_services test_app')
    end

    describe 'with excluded services' do
      let(:exclude_services) { ['test_service', 'test_service1'] }

      it 'must use reload_services and exclude the specified services' do
        cap.must_have_run('sudo /usr/local/bin/reload_services -s test_service -s test_service1 test_app')
      end

      it 'must use check all services' do
        cap.must_have_run('sudo /usr/local/bin/check_services test_app')
      end
    end

    describe "with allow_check_services_failure" do
      let(:allow_check_services_failure) { true }

      it 'must ignore check_services failure' do
        cap.must_have_run('sudo /usr/local/bin/reload_services test_app')
        cap.must_have_run("sudo /usr/local/bin/check_services test_app || echo 'Failure ignored'")
      end
    end
  end
end
