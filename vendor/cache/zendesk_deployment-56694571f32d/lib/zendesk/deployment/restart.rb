require 'zendesk_deployment'
require 'capistrano/recipes/deploy/scm/git'

module Zendesk::Deployment
  module Restart
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :application

        set_default :exclude_services, []
        set_default :allow_check_services_failure, false

        namespace :deploy do
          desc 'Restart the application.'
          task :restart, :except => { :no_release => true } do
            logger.info "Restarting #{application}"
            if exclude_services.any?
              exclude = exclude_services.map { |serv| "-s #{serv}" }.join(' ') << " "
            end
            run "sudo /usr/local/bin/reload_services #{exclude}#{application}"

            logger.info "Checking #{application}"
            check_services_failure = " || echo 'Failure ignored'" if allow_check_services_failure
            run "sudo /usr/local/bin/check_services #{application}#{check_services_failure}"
          end
        end
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Restart)
  end
end
