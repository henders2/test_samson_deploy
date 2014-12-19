require 'zendesk_deployment'
require_relative 'code_changes'

module Zendesk::Deployment
  module Migrations
    def self.extended(config)
      config.extend(Utils)
      config.extend(CodeChanges)

      config.load do
        required_variable :rake, :provided_by => :bundler
        required_variable :production?, :provided_by => :environment_selector

        set_default(:check_for_pending_migrations?) { production? }
        set_default :abort_if_pending_migrations_rake_task, 'db:abort_if_pending_migrations'

        namespace :deploy do
          task :abort_if_pending_migrations, :roles => :db, :only => { :primary => true } do
            if check_for_pending_migrations?
              logger.info "Checking for pending database migrations"

              rake_output = capture "cd #{release_path} && #{rake} #{abort_if_pending_migrations_rake_task} 2>&1 || echo 'rake aborted!'"

              if rake_output =~ /update your database then try again/im
                logger.info rake_output
                abort("There are pending migrations. Unset check_for_pending_migrations? or run them manually.")
              elsif rake_output =~ /rake aborted!/
                logger.info rake_output
                abort("Deploy error: rake task did not succeed!")
              end
            else
              migrate
            end
          end

          after 'deploy:fetch_archive_from_mirror', 'deploy:abort_if_pending_migrations'

          task :migrate, :roles => :db, :only => { :primary => true } do
            if changes_in?('db/migrate')
              logger.info "Running database migrations"
              run "cd #{release_path} && #{rake} db:migrate"
            end
          end
        end
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Migrations)
  end
end
