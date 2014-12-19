module Zendesk::Deployment
  module ReportStatus
    def self.status(exception)
      color, text = if exception
        [:red, 'FAILURE']
      else
        [:green, 'SUCCESS']
      end
      HighLine::String.new("Status: #{text}").send(color)
    end

    def self.extended(config)
      config.load do
        namespace :deploy do
          desc 'Setup for status report on exit.'
          task :report_status_setup do
            at_exit { logger.important Zendesk::Deployment::ReportStatus.status($!) }
          end
        end

        before "deploy:fetch_archive_from_mirror", "deploy:report_status_setup"
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(ReportStatus)
  end
end
