require_relative 'helper'
require 'zendesk/deployment/challenge'

describe Zendesk::Deployment::Challenge do
  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::Challenge)

    cap.set(:interactive?, true)
  end

  describe 'in a non-production environment' do
    before do
      cap.set(:production?, false)
      cap.set(:deployer_drunk?) { abort }
    end

    describe 'deploy:build' do
      before { cap.find_and_execute_task('deploy:build') }

      it 'should not challenge the deployer' do
        cap.aborted?.must_equal false
      end
    end

    describe 'deploy:release' do
      before { cap.find_and_execute_task('deploy:release') }

      it 'should not challenge the deployer' do
        cap.aborted?.must_equal false
      end
    end
  end

  describe 'in a production environment' do
    before { cap.set(:production?, true) }

    describe 'deploy:build' do
      it 'should challenge the deployer' do
        cap.set(:deployer_drunk?, true)
        cap.find_and_execute_task('deploy:build')
        cap.aborted?.must_equal true
      end

      it 'should allow non-drunk deployers' do
        cap.set(:deployer_drunk?, false)
        cap.find_and_execute_task('deploy:build')
        cap.aborted?.must_equal false
      end
    end

    describe 'deploy:release' do
      it 'should challenge the deployer' do
        cap.set(:deployer_drunk?, true)
        cap.find_and_execute_task('deploy:release')
        cap.aborted?.must_equal true
      end

      it 'should allow non-drunk deployers' do
        cap.set(:deployer_drunk?, false)
        cap.find_and_execute_task('deploy:release')
        cap.aborted?.must_equal false
      end
    end
  end
end
