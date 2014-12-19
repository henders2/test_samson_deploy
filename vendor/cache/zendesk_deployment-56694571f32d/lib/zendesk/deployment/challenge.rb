require 'zendesk_deployment'
require 'zendesk/deployment/environment_selector'

module Zendesk::Deployment
  module Challenge
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :production?, :provided_by => :environment_selector

        set_default(:deployer_drunk?) do
          a, b = rand(10), rand(10)
          result = a + b

          answer = ask("What is #{a} + #{b} ?", Integer)

          if answer != result
            logger.important "Dude it's #{result}."
            true
          else
            # giving you time to realize that you are actually drunk
            sleep(3)
            false
          end
        end

        namespace :deploy do
          task :challenge do
            if interactive? && production? && deployer_drunk?
              abort("You should not be deploying!")
            end
          end
        end

        before "deploy:build", "deploy:challenge"
        before "deploy:release",  "deploy:challenge"
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Challenge)
  end
end
