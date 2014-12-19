require_relative "helper"
require "zendesk/deployment/notify"

describe Zendesk::Deployment::Notify do
  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::FullLog)
    cap.extend(Zendesk::Deployment::Notify)

    @revision_set = Zendesk::Deployment::Notify::RevisionSet.new("git@github.com:/hello/there.git", "Previous Revision", "Current Revision")
  end

  describe Zendesk::Deployment::Notify::RevisionSet do
    subject { @revision_set }

    describe "#map_sha_tag" do
      it "returns the revision when no tag is found" do
        assert_equal "hello", subject.map_sha_tag("hello")
      end

      it "returns the tag when a such is found" do
        skip if ENV["TRAVIS"] # travis uses a shallow clone -> no tags present + making a fake tag crashes other tests
        assert_equal "v0.0.1", subject.map_sha_tag("0f77f809e3f73555973af6e2ac90b07ab5a95a77")
      end
    end

    describe "#public_git_url" do
      it "turns the repository reference into a GH browser URL" do
        assert_equal "https://github.com//hello/there", subject.public_git_url
      end
    end

    describe "#delta_url" do
      it "returns a URL to display the deploy delta on GH" do
        assert_equal "https://github.com//hello/there/compare/Previous Revision...Current Revision", subject.delta_url
      end
    end
  end

  describe Zendesk::Deployment::Notify::Message do
    subject do
      Zendesk::Deployment::Notify::Message.new(
        :deployer     => "Deployer",
        :application  => "Some Application",
        :environment  => "Environment",
        :rails_env    => "Rails Environment",
        :revision_set => @revision_set,
        :deploy_log   => "Deploy Log"
      )
    end

    describe "#subject" do
      it "returns the appropriate subject" do
        assert_equal "[ZD DEPLOY] Deployer deployed Some Application to Environment (Rails Environment): Current Revision", subject.subject
      end
    end

    describe "#path" do
      it "returns a time stamped path" do
        assert_match /\/tmp\/deploy_notify_message_some_application_\d+\.log/, subject.path
      end
    end

    describe "#body" do
      it "contains a diff URL" do
        assert_match /#{"https://github.com//hello/there/compare/Previous Revision...Current Revision"}/, subject.body
      end

      it "contains a deploy log" do
        assert_match /#{"Deploy Log"}/, subject.body
      end
    end
  end

  describe "deploy:notify" do
    before do
      cap.set :email_notification, "someone@example.org"
      cap.set :current_revision, "Previous"
      cap.set :repository,  'file://' + File.expand_path("..", File.dirname(__FILE__))
      cap.set :deployer,    "Someone"
      cap.set :application, "Application"
      cap.set :environment, "Evironment"
      cap.set :rails_env,   "Rails"
      cap.set :revision,    "Revision"
      cap.set :deploy_host, "DeployHost"

      cap.find_and_execute_task("deploy:notify")
    end

    it "sent the email" do
      cap.must_have_run(
       "cat /tmp/deploy_notify_message_application_#{Time.now.to_i}.log | mail -s '[ZD DEPLOY] Someone deployed Application to Evironment (Rails): Revision' someone@example.org",
       :hosts => "DeployHost"
      )
    end
  end

  describe "deploy:notify with no recipients" do
    before do
      cap.set :email_notification, []
      cap.set :current_revision, "Previous"
      cap.set :repository,  'file://' + File.expand_path("..", File.dirname(__FILE__))
      cap.set :deployer,    "Someone"
      cap.set :application, "Application"
      cap.set :environment, "Evironment"
      cap.set :rails_env,   "Rails"
      cap.set :revision,    "Revision"

      cap.find_and_execute_task("deploy:notify")
    end

    it "does nothing" do
      cap.runs.must_be_empty
    end
  end

end
