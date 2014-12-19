require_relative 'helper'
require 'zendesk/deployment/check_setup'
require 'fileutils'

describe Zendesk::Deployment::CheckSetup do
  before do
    cap.run_locally!
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::CheckSetup)
    cap.set :deployer, 'tester'
    cap.set :environment, 'pod1'
    cap.server 'test', :test
  end

  describe 'deploy:check_setup' do
    it "will abort if the deploy_to path doesn't exist" do
      cap.set :deploy_to, '/nowheresville'
      assert !File.exist?(cap.deploy_to)
      assert_raises Capistrano::CommandError do
        cap.find_and_execute_task('deploy:check_setup')
      end
    end

    it "will go ahead if the deploy_to path exists" do
      cap.set :deploy_to, Dir.mktmpdir
      cap.find_and_execute_task('deploy:check_setup')
      assert cap.aborted?.must_equal false
    end
  end
end
