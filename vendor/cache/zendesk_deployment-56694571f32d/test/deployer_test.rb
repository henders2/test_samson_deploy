require_relative 'helper'
require 'zendesk/deployment/deployer'

describe Zendesk::Deployment::Deployer do
  before do
    cap.extend(Zendesk::Deployment::Deployer)
  end

  describe '#deployer' do
    it 'reads the username from ENV[\'DEPLOYER\']' do
      ENV['DEPLOYER'] = 'test_user_name'
      cap.deployer.must_equal 'test_user_name'
    end

    it 'reads the username from ENV[\'USER\'] when no ENV[\'DEPLOYER\']' do
      ENV['DEPLOYER'] = nil
      cap.deployer.must_equal ENV['USER']
    end
  end
end
