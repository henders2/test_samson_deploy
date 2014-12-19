require_relative 'helper'
require 'zendesk/deployment/show_hosts'

describe Zendesk::Deployment::ShowHosts do
  before do
    cap.extend(Zendesk::Deployment::ShowHosts)
  end

  describe 'deploy:show_hosts' do
    before do
      cap.role :deploy, "foobar1"
      cap.role :deploy, "foobar2", :primary => true
      $stdout = StringIO.new
    end

    it 'show print out the list of hosts in the current deploy role' do
      cap.find_and_execute_task 'deploy:show_hosts'
      $stdout.rewind
      assert_equal "foobar1         {:roles=>[:deploy]}\nfoobar2         {:roles=>[:deploy], :primary=>true}\n", $stdout.read
    end

    after do
      $stdout = STDOUT
    end
  end
end
