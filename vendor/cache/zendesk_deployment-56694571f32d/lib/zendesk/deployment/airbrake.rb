require 'zendesk_deployment'
require 'zendesk/deployment/deployer'
require 'airbrake'
require 'airbrake_tasks'

module Zendesk::Deployment
  module Airbrake
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :repository
        required_variable :revision,   :provided_by => :mirror_strategy
        required_variable :rails_env,  :provided_by => :environment_selector

        set_default :airbrake_initializer, 'config/initializers/airbrake.rb'

        on :load do
          if airbrake_initializer
            begin
              require "./#{airbrake_initializer}"
            rescue LoadError, NameError
            end
          end

          if ::Airbrake.configuration.api_key.nil?
            abort 'You need to configure Airbrake'
          end
        end

        namespace :deploy do
          task :notify_airbrake do
            logger.info 'Notifying Airbrake of the deploy'
            begin
              ::AirbrakeTasks.deploy(
                :rails_env      => rails_env,
                :scm_revision   => revision,
                :scm_repository => repository,
                :local_username => deployer
              )
            rescue EOFError, SocketError
              logger.important 'An error occurred during the Airbrake deploy notification.'
            end
          end
        end

        after 'deploy:release', 'deploy:notify_airbrake'
        # after 'deploy:switch', 'deploy:notify_airbrake'
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Airbrake)
  end
end
