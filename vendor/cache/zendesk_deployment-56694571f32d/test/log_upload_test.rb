require_relative 'helper'
require 'zendesk/deployment/log_upload'
require 'fileutils'
require 'tmpdir'

describe(Zendesk::Deployment::LogUpload) do
  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::FullLog)
    cap.extend(Zendesk::Deployment::LogUpload)
    cap.set :deployer, 'tester'
    cap.set :environment, 'pod1'
    cap.server 'test', :test
    cap.server 'test2', :test
    cap.set :application, "APPLICATION"
    cap.set :log_path, Dir.mktmpdir("test_upload")
  end

  after do
    FileUtils.rm_rf(cap.log_path)
  end

  describe 'uploading the deploy log' do
    describe 'when no connections to servers where made' do
      before do
        cap.find_and_execute_task(:upload_log)
      end

      it 'will not create a "deploy" sub-path of the log directory and upload the full log there.' do
        cap.runs.must_be :empty?
      end

      it 'will not upload anything' do
        cap.puts.must_be :empty?
      end
    end

    describe 'when connections to servers where made' do
      before do
        @connected_hosts = [cap.find_servers.first]
        # this line simulates that we have a session to the host
        cap.sessions[@connected_hosts.first] = nil
        cap.find_and_execute_task(:upload_log)
      end

      it 'will create a "deploy" sub-path of the log directory and upload the full log there.' do
        cap.must_have_run("mkdir -p #{cap.log_path + '/deploy'}", :hosts => @connected_hosts, :skip_hostfilter => true)
      end

      it 'only uploads to the connected hosts' do
        cap.puts.size.must_equal 1
        cap.puts.first[:options][:hosts].must_equal @connected_hosts
        cap.puts.first[:options][:skip_hostfilter].must_equal true
      end

      it 'creates a file with the application and deployer in the name' do
        cap.puts.size.must_equal 1
        cap.puts.first[:path].must_match /\/deploy\/APPLICATION-.*-tester\.log/
      end

      it 'summarizes the deploy into an appended-to-file' do
        cap.runs.detect { |r| r[:command] =~ /^echo/ }.wont_be_nil
      end

      it 'summarizes the deploy only on the connected hosts' do
        cap.puts.size.must_equal 1
      end
    end

  end
end
