require_relative 'helper'
require 'zendesk/deployment/code_changes'
require 'tmpdir'

describe Zendesk::Deployment::CodeChanges do
  let(:release_path) { Dir.pwd }

  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::CodeChanges)
    cap.run_locally!
    cap.set(:release_path, "new")
    cap.set(:current_path, "old")
    cap.set(:current_revision, "HEAD^")
    cap.set(:revision, "HEAD")
  end

  around do |test|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p("new/public/assets")
        FileUtils.mkdir("old")
        File.write("old/REVISION", "HEAD^")
        FileUtils.mkdir_p("old/public/assets")
        `git init  2>&1 && git commit -m 'a' --allow-empty  2>&1 && git commit -m 'a' --allow-empty 2>&1`
        test.call
      end
    end
  end

  describe '#on_outdated_assets' do
    let(:runs) { cap.runs.map { |r| r[:command] } }
    let(:revision_cmd) { "cat old/REVISION || true" }
    let(:folder_cmd) { "test -d old/public/assets ; echo $?" }

    def call
      result = false
      cap.on_outdated_assets { result = true }
      result
    end

    it 'copies assets' do
      File.write("old/public/assets/bar", "TEST")
      FileUtils.mkdir_p("old/public/assets/foo")
      File.write("old/public/assets/foo/bar", "TEST")
      call.must_equal false
      assert File.exist?("new/public/assets/bar")
      assert File.exist?("new/public/assets/foo/bar")
      runs.must_equal ["test -d old/public/assets && grep HEAD^ old/REVISION && rsync -a old/public/assets/. new/public/assets"]
    end

    it 'does not copy assets if Gemfile was changed' do
      `touch Gemfile && git add Gemfile && git commit -m 'Gemfile'`
      call.must_equal true
    end

    it 'does not copy assets if a file inside app/assets was changed' do
      `mkdir -p app/assets && touch app/assets/foo && git add app && git commit -m 'assets'`
      call.must_equal true
    end

    it 'does not copy assets if we are not releasing' do
      cap.set(:current_path, nil)
      call.must_equal true
      runs.must_equal []
    end

    it "does not copy assets if REVISIONS are not matching" do
      File.write("old/REVISION", "XXX")
      call.must_equal true
      runs.wont_equal []
    end

    it "does not copy assets if public/assets is missing" do
      FileUtils.rm_rf("old/public/assets")
      call.must_equal true
      runs.wont_equal []
    end
  end
end
