require 'zendesk/deployment'

set :application, 'test_samson_deploys'
set :repository,  'git@github.com:zendesk-shender/test_samson_deploy.git'
set :email_notification, ['shender@zendesk.com']

desc 'Select my random server'
task :local_server do
  set :environment, 'test_server' # Just name this environment
  set :rails_env, 'staging'       # The RAILS_ENV of this environment
  role :deploy, 'localhost'  # Give your server the :deploy role
end
