require 'zendesk_deployment'

module Zendesk::Deployment
  module ShowHosts
    def self.extended(config)
      config.load do
        namespace :deploy do
          desc "show the list of deploy targets"
          task :show_hosts do
            find_servers.each do |server|
              description = server.to_s.ljust(15)
              options = {:roles => role_names_for_host(server)}.merge(server.options)
              description << " #{options.inspect}"
              puts description
            end
          end
        end

      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(ShowHosts)
  end
end
