require_relative 'helper'
require 'zendesk/deployment/committish'

describe Zendesk::Deployment::Committish do
  def tag(thing, tag)
    sh "git checkout #{thing} 2>&1 && git tag #{tag} 2>&1 && git checkout master 2>&1"
  end

  def sh(command)
    result = `#{command}`
    raise "Failed: #{result}" unless $?.success?
    result
  end

  def commit(thing)
    Zendesk::Deployment::Committish.new(thing)
  end

  around do |test|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        sh "git init 2>&1 && git commit -m 'a' --allow-empty  2>&1 && git commit -m 'a' --allow-empty 2>&1"
        test.call
      end
    end
  end

  it "finds tag" do
    tag "HEAD^", "v1.2.3"
    commit = commit("v1.2.3")
    assert commit.valid_tag?
    assert_equal "v1.2.3", commit.to_s
  end

  it "finds pre" do
    tag "HEAD^", "v1.2.3.4"
    commit = commit("v1.2.3.4")
    assert commit.valid_tag?
    assert_equal "v1.2.3.4", commit.to_s
  end

  it "finds pre with letters" do
    tag "HEAD^", "v1.2.3.patched"
    commit = commit("v1.2.3.patched")
    assert commit.valid_tag?
    assert_equal "v1.2.3.patched", commit.to_s
  end

  it "can compare tags" do
    tag "HEAD^", "v1.2.3"
    tag "HEAD", "v1.2.4"
    assert_operator commit("v1.2.4"), :>, commit("v1.2.3")
  end

  it "works with non-tags" do
    assert_equal 0, commit("v1.2.4") <=> commit("master")
  end
end
