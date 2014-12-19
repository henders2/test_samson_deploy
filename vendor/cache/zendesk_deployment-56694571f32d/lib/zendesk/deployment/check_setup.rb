require 'zendesk_deployment'
require 'zendesk/deployment/deployer'
module Zendesk::Deployment
  module CheckSetup
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :application
        required_variable :deploy_to,   :provided_by => :mirror_strategy

        namespace :deploy do
          desc "Ensure the deploy is setup across hosts"
          task :check_setup, :except => { :no_release => true } do
            run "test -d #{deploy_to} && echo ok" do |channel, stream, data|
              if data.chomp != "ok"
                abort "Failed to find #{deploy_to} on #{channel[:host]} -- please run ' cap deploy:setup '"
              end
            end
          end
        end

        before "deploy:lock_and_unlock", "deploy:check_setup"
      end
    end
  end

  Capistrano::Configuration.instance(:must_exist).extend(CheckSetup)
end


