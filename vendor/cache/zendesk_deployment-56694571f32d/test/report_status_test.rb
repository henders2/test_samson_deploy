require_relative 'helper'
require 'zendesk/deployment/report_status'

describe Zendesk::Deployment::ReportStatus do
  describe '.report_status' do
    it "reports success" do
      assert_includes Zendesk::Deployment::ReportStatus.status(nil), "SUCCESS"
    end

    it "reports error" do
      assert_includes Zendesk::Deployment::ReportStatus.status(SystemExit.new(1)), "FAILURE"
    end
  end
end
