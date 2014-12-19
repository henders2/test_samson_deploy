require 'zendesk_deployment'

module Zendesk::Deployment
  module RubyVersion
    def rbenv_env(ruby_version)
      { 'RBENV_VERSION' => ruby_version }
    end

    def self.extended(config)
      config.extend(Utils)

      config.load do
        set_default :ruby_versions, []

        on :load do
          all_ruby_versions = fetch(:ruby_versions, [])
          all_ruby_versions += [fetch(:ruby_version)]
          all_ruby_versions.compact!
          all_ruby_versions.uniq!
          set :ruby_versions, all_ruby_versions

          default_environment.merge!(rbenv_env(fetch(:ruby_version)))
        end
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(RubyVersion)
  end
end
