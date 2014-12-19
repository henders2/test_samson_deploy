require_relative 'helper'
require 'zendesk/deployment/lock'
require 'fileutils'
require 'tmpdir'

describe Zendesk::Deployment::Lock do
  before do
    cap.run_locally!
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::Lock)
    cap.set :deployer, 'tester'
    cap.set :environment, 'pod1'
    cap.server 'test', :test
  end

  describe 'lock_path' do
    it 'is in the shared log directory' do
      cap.set :log_path, 'LOG_PATH'
      cap.set :application, 'APPLICATION'
      cap.lock_path.must_equal 'LOG_PATH/.APPLICATION_deploy_lock'
    end
  end

  describe 'lock_timeout' do
    it 'defaults to 24 hours' do
      cap.lock_timeout.must_equal 24 * 60 * 60
    end
  end

  describe 'deploy:lock' do
    before do
      cap.set :lock_path, File.join(Dir.tmpdir, 'test_lock')
    end

    describe 'when no current lock exists' do
      before do
        FileUtils.rm_f(cap.lock_path)
        cap.find_and_execute_task('deploy:lock')
      end

      it 'stores a lock file in the lock path' do
        File.file?(cap.lock_path).must_equal true
        File.read(cap.lock_path).must_equal "#{Time.now.to_i} #{cap.deployer}"
      end

      it 'does not abort' do
        cap.aborted?.must_equal false
      end
    end

    describe 'when a recent lock exists' do
      before do
        File.open(cap.lock_path, 'w') { |f| f.write("#{Time.now.to_i - 5} some_dude") }
        cap.find_and_execute_task('deploy:lock')
      end

      it 'aborts' do
        cap.aborted?.must_equal true
      end
    end

    describe 'when an expired lock exists' do
      before do
        File.open(cap.lock_path, 'w') { |f| f.write("#{Time.now.to_i - 5000000} some_dude") }
        cap.find_and_execute_task('deploy:lock')
      end

      it 'does not abort' do
        cap.aborted?.must_equal false
      end
    end
  end

  describe 'deploy:unlock' do
    before do
      cap.set :lock_path, File.join(Dir.tmpdir, 'test_lock')
      File.open(cap.lock_path, 'w') { |f| f.write("#{Time.now.to_i - 5} some_dude") }
      cap.find_and_execute_task('deploy:unlock')
    end

    it 'removed the lock' do
      File.exist?(cap.lock_path).must_equal false
    end
  end

  describe 'deploy:release' do
    before { cap.set :lock_path, File.join(Dir.tmpdir, 'test_lock') }

    it 'locks' do
      cap.find_and_execute_task('deploy:release')
      cap.must_have_invoked 'deploy:lock_and_unlock'
    end
  end
end
