require_relative 'helper'
require 'zendesk/deployment/airbrake'

describe Zendesk::Deployment::Airbrake do
  before do
    cap.extend(Zendesk::Deployment::Deployer)
    cap.extend(Zendesk::Deployment::Airbrake)

    ::Airbrake.configuration = ::Airbrake::Configuration.new
  end

  describe 'configuration' do
    describe 'when the configuration file is not found' do
      before do
        cap.set :airbrake_initializer, 'foo'
      end

      describe 'and no other configuration is in place' do
        it 'aborts' do
          cap.trigger :load
          cap.aborted?.must_equal true
        end
      end

      describe 'but airbrake is configured' do
        before do
          ::Airbrake.configure do |config|
            config.api_key = 'api_key'
          end
        end

        it 'does not abort' do
          cap.trigger :load
          cap.aborted?.must_equal false
        end
      end
    end

    describe 'when the configuration file is found' do
      before do
        cap.set :airbrake_initializer, 'test/airbrake_configs/airbrake.rb'
        cap.trigger :load
      end

      it 'loads the configuration' do
        Airbrake.configuration.api_key.must_equal 'api_key'
      end

      it 'does not abort' do
        cap.aborted?.must_equal false
      end
    end
  end

  describe 'deploy:notify_airbrake' do
    before do
      cap.set :rails_env, 'test'
      cap.set :revision, 'abcd'
      cap.set :repository, 'repository'

      ::Airbrake.configure do |config|
        config.api_key = 'api_key'
      end
    end

    it 'works' do
      airbrake_tasks_args = nil

      ::AirbrakeTasks.stub :deploy, lambda {|args| airbrake_tasks_args = args } do
        cap.find_and_execute_task 'deploy:notify_airbrake'
      end

      airbrake_tasks_args.must_equal(
        :rails_env      => cap.rails_env,
        :scm_revision   => cap.revision,
        :scm_repository => cap.repository,
        :local_username => cap.deployer
      )
    end

    it 'handles a SocketError' do
      ::AirbrakeTasks.stub :deploy, lambda {|args| raise SocketError } do
        cap.find_and_execute_task 'deploy:notify_airbrake'

        # This assures a raised socket error in airbrake notification does
        # not prevent the task from completing cleanly.
        assert true
      end
    end
  end
end
