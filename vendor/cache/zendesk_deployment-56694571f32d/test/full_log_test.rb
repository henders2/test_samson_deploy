require_relative 'helper'
require 'zendesk/deployment/full_log'

describe Zendesk::Deployment::FullLog do
  before do
    cap.extend(Zendesk::Deployment::FullLog)
  end

  describe '#full_log' do
    it 'appends the output to full_log' do
      previous_log = cap.full_log
      cap.logger.important '1st log line'
      cap.full_log.must_equal "*** 1st log line\n"
      cap.logger.info '2nd log line'
      cap.full_log.must_equal "*** 1st log line\n ** 2nd log line\n"
    end

    it 'appends the output to full_log even when below log level' do
      cap.logger.level = Capistrano::Logger::IMPORTANT
      previous_log = cap.full_log
      cap.logger.info '1st log line'
      cap.full_log.must_equal " ** 1st log line\n"
      cap.logger.debug '2nd log line'
      cap.full_log.must_equal " ** 1st log line\n  * 2nd log line\n"
    end
  end
end
