require 'zendesk_deployment'
require 'stringio'

module Zendesk::Deployment
  module FullLog
    class Logger
      attr_reader :screen_logger, :full_logger

      def initialize(config)
        @config        = config
        @screen_logger = config.logger
        @full_log      = StringIO.new
        @full_logger   = Capistrano::Logger.new(:output => @full_log, :level => Capistrano::Logger::TRACE, :disable_formatters => true)
      end

      def close
        @screen_logger.close
        @full_logger.close
      end

      def log(level, message, line_prefix=nil)
        @screen_logger.log(level, message, line_prefix)
        @full_logger.log(level, message, line_prefix)
        @config.reset!(:full_log)
      end

      def important(message, line_prefix=nil)
        log(Capistrano::Logger::IMPORTANT, message, line_prefix)
      end

      def info(message, line_prefix=nil)
        log(Capistrano::Logger::INFO, message, line_prefix)
      end

      def debug(message, line_prefix=nil)
        log(Capistrano::Logger::DEBUG, message, line_prefix)
      end

      def trace(message, line_prefix=nil)
        log(Capistrano::Logger::TRACE, message, line_prefix)
      end

      def level=(level)
        @screen_logger.level = level
      end

      def full_log
        @full_log.string
      end
    end

    def self.extended(config)
      config.load do
        @logger = Logger.new(config)
        set :logger, @logger

        set(:full_log) { logger.full_log }
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(FullLog)
  end
end
