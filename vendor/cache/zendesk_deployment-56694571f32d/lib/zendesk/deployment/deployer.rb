require 'zendesk_deployment'

module Zendesk::Deployment
  module Deployer
    def self.extended(config)
      config.load do
        set(:deployer) { ENV['DEPLOYER'] || ENV['USER'] }
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Deployer)
  end
end
