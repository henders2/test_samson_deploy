require 'zendesk_deployment'
require 'zendesk/deployment/full_log'
require 'zendesk/deployment/deployer'

module Zendesk::Deployment
  module LogUpload
    def deploy_log_summary
      revinfo = ""
      if exists?(:committish) && committish
        revinfo << committish.describe
      end
      if exists?(:current_committish) && current_committish
        revinfo << " (was #{current_committish.describe})"
      end

      "#{Time.now.strftime('%Y%m%d-%H%M')}: #{deployer} deployed #{revinfo}"
    end

    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :application
        required_variable :log_path,   :provided_by => :mirror_strategy

        task :upload_log do
          # sessions.keys is a list of all the servers that we already connected to
          servers = find_servers({:except => { :no_release => true }}) & sessions.keys

          reject_hosts = ["localhost", Socket.gethostname]
          servers.reject! { |server| reject_hosts.include? server.to_s }

          if servers.any?
            remote_log_directory = "#{log_path}/deploy"
            run "mkdir -p #{remote_log_directory}", :hosts => servers, :skip_hostfilter => true
            remote_log_path = "#{remote_log_directory}/#{application}-#{Time.now.strftime('%Y%m%d-%H%M')}-#{deployer}.log"
            logger.info "uploading deploy logs: #{remote_log_path}"
            put full_log, remote_log_path, :via => :scp, :hosts => servers, :skip_hostfilter => true

            summary_deploy_log = remote_log_directory + "/#{application}-summary.log"
            run "echo \"#{deploy_log_summary}\" >> #{summary_deploy_log}", :hosts => servers, :skip_hostfilter => true
          end
        end

        at_exit { upload_log }
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(LogUpload)
  end
end
