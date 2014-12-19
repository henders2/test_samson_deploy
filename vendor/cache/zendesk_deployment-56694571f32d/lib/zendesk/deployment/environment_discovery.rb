require 'tmpdir'
require 'yaml'
require 'deep_merge'
require 'fileutils'

module Zendesk
  module Deployment
    class EnvironmentDiscovery
      attr_accessor :location, :local_location

      def initialize(location = nil)
        location ||=  ENV["ZENDESK_HOSTS_FILE"] || '/etc/zendesk/hosts.yml'
        @location = location
      end

      def each_host_config(&block)
        host_configs.each do |host, conf|
          conf['deploy_projects'] ||= []
          yield(host, conf)
        end
      end

      def pods
        @pods ||= host_configs.reduce(Hash.new) do |memo, (_, conf)|
          pod = conf['pod']
          environment = conf['environment']

          if pod.to_s =~ /\A\d+\Z/
            if pod && environment
              (memo[environment] ||= Set.new) << pod
            end
          end

          memo
        end
      end

      protected

      def host_configs
        File.exist?(location) ? YAML.load(File.read(location)) : {}
      end
    end
  end
end
