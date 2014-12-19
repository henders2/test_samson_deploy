require_relative 'helper'
require 'zendesk/deployment/tags'

describe Zendesk::Deployment::Utils do
  before do
    cap.extend(Zendesk::Deployment::Utils)
  end

  describe "confirm" do
    it "does not need to ask when it is not interactive" do
      cap.set(:interactive?, false)

      agree = lambda do |q|
        assert false
      end

      Capistrano::CLI.ui.stub(:agree, agree) do
        cap.confirm("xxx")
      end
    end

    it "needs to ask when it is interactive" do
      cap.set(:interactive?, true)

      question = nil
      agree = lambda do |q|
        question = q
        true
      end

      Capistrano::CLI.ui.stub(:agree, agree) do
        cap.confirm("xxx")
      end

      question.must_equal 'xxx. Are you sure?'
    end
  end
end
