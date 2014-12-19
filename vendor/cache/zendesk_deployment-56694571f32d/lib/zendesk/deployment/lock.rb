require 'zendesk_deployment'
require 'zendesk/deployment/deployer'

module Zendesk::Deployment
  module Lock
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :application
        required_variable :log_path,    :provided_by => :mirror_strategy

        set_default(:lock_path) { "#{log_path}/.#{application}_deploy_lock" }
        set_default :lock_timeout, 86400

        namespace :deploy do
          desc 'Lock deploys.'
          task :lock, :except => { :no_release => true } do
            current_lock = capture("cat #{lock_path} 2>&- || true")
            now = Time.now.to_i

            if !current_lock.empty?
              locked_at = current_lock.split[0].to_i
              locked_by = current_lock.split[1]

              lock_time = now - locked_at

              if lock_time < lock_timeout
                msg = [
                  "failed to lock",
                  "deploy locked by #{locked_by} #{lock_time} seconds ago"
                ]
                msg << "use 'bundle exec cap #{environment} deploy:unlock' to remove this lock" if exists?(:environment)
                abort msg.join("\n")
              end
            end

            transaction do
              on_rollback do
                logger.important "could not lock deploys, unlocking all deploys immediately"
                unlock
              end

              logger.info "locking deploys for #{lock_timeout} seconds"
              put "#{now} #{deployer}", lock_path, :via => :scp
            end
          end

          task :lock_and_unlock, :except => { :no_release => true } do
            lock
            at_exit { unlock }
          end

          desc 'Unlock deploys.'
          task :unlock, :except => { :no_release => true } do
            logger.info "unlocking deploys"
            run "rm -f #{lock_path}"
          end
        end

        before "deploy:release", "deploy:lock_and_unlock"
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Lock)
  end
end
