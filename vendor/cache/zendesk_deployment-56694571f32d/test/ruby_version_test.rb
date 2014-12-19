require_relative 'helper'
require 'zendesk/deployment/ruby_version'

describe Zendesk::Deployment::RubyVersion do
  before do
    cap.extend(Zendesk::Deployment::RubyVersion)
  end

  describe 'default_environment' do
    before { cap.set :ruby_version, '1.9.3' }

    describe 'with no ruby version defined' do
      before { cap.unset :ruby_version }
      it 'blows up' do
        assert_raises(IndexError) { cap.trigger :load }
      end
    end

    it 'uses the specified ruby' do
      cap.trigger :load
      cap.default_environment['RBENV_VERSION'].must_equal '1.9.3'
    end
  end

  describe 'ruby_versions' do
    it 'is updated to include ruby_version' do
      cap.set :ruby_version, '1.9.3'
      cap.set :ruby_versions, ['ree']
      cap.trigger :load
      cap.ruby_versions.sort.must_equal ['1.9.3', 'ree']
    end
  end
end
