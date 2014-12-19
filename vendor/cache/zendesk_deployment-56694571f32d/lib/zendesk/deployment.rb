require 'capistrano'

Capistrano::Configuration.instance(:must_exist).load do |config|
  features = [
    'restart',
    'environment_selector',
    'warn_if_local',
    'challenge',
    'ruby_version',
    'code_changes',
    'deployer',
    'show_hosts',
    'log_upload',
    'full_log',
    'notify',
    'tags',
    'mirror_strategy',
    'bundler',
    'lock',
    'check_setup',
    'report_status'
  ]

  exclude_features = fetch(:disable_deploy_features, []).map(&:to_s)
  features -= exclude_features

  features.each do |feature|
    require "zendesk/deployment/#{feature}"
  end

  set :user, 'zendesk'
  set :ruby_version, File.read(".ruby-version").strip if File.exist?(".ruby-version")
end
