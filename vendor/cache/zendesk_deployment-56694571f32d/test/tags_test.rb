require_relative 'helper'
require 'zendesk/deployment/tags'

describe Zendesk::Deployment::Tags do
  def self.it_must_ask_for_confirmation(task)
    it 'must ask for confirmation' do
      $confirmed = false
      def cap.confirm(what)
        $confirmed = true
      end
      cap.find_and_execute_task(task)

      $confirmed.must_equal true, "Did not ask for confirmation"
    end
  end

  def self.it_wont_ask_for_confirmation(task)
    it 'wont ask for confirmation' do
      $confirmed = false
      def cap.confirm(what)
        $confirmed = true
      end
      cap.find_and_execute_task(task)

      $confirmed.must_equal false, "Asked for confirmation"
    end
  end

  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::Tags)
    cap.set :current_path, File.expand_path('..', File.dirname(__FILE__))
    cap.set(:revision) { cap.tag || cap.fetch(:branch, 'HEAD') }
    cap.set :current_revision, 'v0.1.0'
    cap.set :previous_revision, 'v0.0.1'
    cap.set :production?, false
  end

  describe 'tag requirement on deploy:release' do
    before { cap.set :confirm_minor_releases?, false }

    describe 'on a non-production environment without a tag' do
      before do
        cap.set :environment, 'master'
        cap.set :production?, false
        cap.set :tag,         nil
      end

      it 'should not abort' do
        cap.find_and_execute_task('deploy:release')
        cap.aborted?.must_equal false
      end
    end

    describe 'on a production environment' do
      before do
        cap.set :environment, 'pod1'
        cap.set :production?, true
        cap.set :gamma?,      false
      end

      describe 'without a tag' do
        before { cap.set :tag, nil }

        it 'should abort' do
          cap.find_and_execute_task('deploy:release')
          cap.aborted?.must_equal true
        end
      end

      describe 'with a tag' do
        before { cap.set :tag, 'v1.0.0' }

        it 'should not abort' do
          cap.find_and_execute_task('deploy:release')
          cap.aborted?.must_equal false
        end
      end
    end

    describe 'on a gamma environment' do
      before do
        cap.set :environment, 'pod1:gamma'
        cap.set :production?, true
        cap.set :gamma?,      true
      end

      describe 'without a tag' do
        before { cap.set :tag, nil }

        it 'should not abort' do
          cap.find_and_execute_task('deploy:release')
          cap.aborted?.must_equal false
        end
      end
    end
  end

  describe 'deploying new major version' do
    before { cap.set :tag, 'v2.0.0' }
    it_must_ask_for_confirmation('deploy:release')
  end

  describe 'deploying new minor version' do
    before { cap.set :tag, 'v1.1.0' }
    it_must_ask_for_confirmation('deploy:release')
  end

  describe 'deploying new patch version' do
    before { cap.set :tag, 'v0.1.2' }
    it_wont_ask_for_confirmation('deploy:release')
  end

  describe 'deploying something that is not a tag' do
    before { cap.set :tag, '7f62d53' }
    it_wont_ask_for_confirmation('deploy:release')
  end
end
