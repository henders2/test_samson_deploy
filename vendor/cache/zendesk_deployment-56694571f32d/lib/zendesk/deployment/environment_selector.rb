require 'zendesk_deployment'
require 'zendesk/deployment/environment_discovery'

module Zendesk::Deployment
  module EnvironmentSelector
    KNOWN_ENVIRONMENTS = ['master', 'staging', 'production'].freeze

    def setup_pod_environment(env, pod, options = {})
      set :gamma?, options.fetch(:gamma, false)
      set :environment, environment_name(env, pod, options)

      set :rails_env, env
      default_environment['RAILS_ENV'] = env

      ssh_options[:forward_agent] = true

      set :gateway, ENV['CAP_SSH_GATEWAY']

      found_servers = []

      environment_discovery.each_host_config do |host, conf|
        next unless host_filter(environment, host, conf, :deploy_projects => deploy_project_name)

        cap_roles = role_mapping(conf.merge('host' => host)) || {}

        cap_roles.each do |cap_role, cap_preds|
          role(cap_role, host, cap_preds)
          found_servers << host
        end
      end

      found_servers.uniq!

      if found_servers.any?
        logger.info "Found these servers for the #{environment} environment: #{found_servers.sort.join(', ')}"
      else
        logger.debug "No servers found for the #{environment} environment"
      end

      finalize_environment_selection
    end

    def host_filter(env, host, conf, options = {})
      _, environment_group, environment_number = env.to_s.match(/([^\d]+)(\d+)?/).to_a
      environment_group = 'production' if environment_group == 'pod'
      environment_number = environment_number ? environment_number.to_i : 1

      return false unless conf['environment'] == environment_group
      return false unless conf['pod'] == environment_number

      options.each do |key, value|
        return false unless Array(conf[key.to_s]).include?(value)
      end

      if environment =~ /:gamma$/
        return false unless host =~ /gamma/
      else
        return false if host =~ /gamma/
      end

      true
    end

    def role_mapping(node)
      roles = []

      hostgroup = node['hostgroup']
      hostgroup = 'app' if ['master', 'staging', 'gamma'].include?(hostgroup)

      { hostgroup.to_sym => {} }
    end

    def environment_name(environment, pod, options = {})
      env = (environment == 'production') ? 'pod' : environment
      env = "#{env}#{pod}"

      options.fetch(:gamma, false) ? "#{env}:gamma" : env
    end

    def self.extended(config)
      config.extend(Utils)

      config.instance_eval do
        def hosts_across_all_projects_with_tag(tag)
          found_servers = []

          environment_discovery.each_host_config do |host, conf|
            next unless host_filter(environment, host, conf, tags: tag)
            found_servers << host
          end

          if found_servers.any?
            logger.info "Found these servers for the #{tag} tag: #{found_servers.sort.join(', ')}"
          else
            logger.debug "No servers found for the #{tag} tag"
          end

          found_servers
        end
      end

      config.load do
        required_variable :application

        set_default(:deploy_project_name) { application }
        set_default :environment_discovery, Zendesk::Deployment::EnvironmentDiscovery.new
        set_default :environments, [:master1, :master2, :staging]

        set(:production?) { fetch(:rails_env, 'production') == 'production' }
        set(:gamma?)      { !!(fetch(:environment, '') =~ /:gamma$/) }

        set(:deploy_host)     { capture('hostname', :hosts => 'localhost').strip }
        set(:on_deploy_host?) { `hostname`.strip == deploy_host }

        task :finalize_environment_selection do
        end

        on :load do
          KNOWN_ENVIRONMENTS.each do |e|
            next unless environment_discovery.pods[e]

            environment_discovery.pods[e].each do |p|
              namespace environment_name(e, p) do
                desc "Select the #{environment_name(e, p)} environment."
                task(:default) do
                  setup_pod_environment(e, p)
                end

                if e == 'production'
                  desc "Select the #{environment_name(e, p)} gamma environment."
                  task(:gamma) do
                    setup_pod_environment(e, p, :gamma => true)
                  end
                end
              end
            end

            desc 'Select the environment environments'
            task e do
              environment_discovery.pods[e].each do |p|
                find_and_execute_task(environment_name(e, p))
              end
            end
          end
        end

      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(EnvironmentSelector)
  end
end
