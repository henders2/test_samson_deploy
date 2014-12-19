require 'zendesk_deployment'
require 'newrelic_rpm'

module Zendesk::Deployment
  module NewRelic
    def find_newrelic_value(files, environment, name)
      Array(files).each do |filename|
        if File.exist?(filename)
          config = ::NewRelic::Agent::Configuration::YamlSource.new(filename, environment)
          return config[name] if config[name]
        end
      end
      return nil
    end

    def self.extended(config)
      config.extend(Utils)

      config.load do
        require 'new_relic/recipes'

        set_default :production_newrelic_config,  ['/data/zendesk/config/newrelic.yml', '/data/samson/config/newrelic.yml']
        set_default :development_newrelic_config, ['./config/newrelic.yml', './config/newrelic.yml.example']

        set_default(:newrelic_license_key) { find_newrelic_value(production_newrelic_config, 'production', :license_key) }
        set_default(:newrelic_appname)     { find_newrelic_value(development_newrelic_config, 'development', :app_name) }
        set_default :newrelic_changelog, 'Not supported by zendesk_deployment'

        after 'deploy:release', 'newrelic:notice_deployment'
        # after 'deploy:switch', 'newrelic:notice_deployment'
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(NewRelic)
  end
end
