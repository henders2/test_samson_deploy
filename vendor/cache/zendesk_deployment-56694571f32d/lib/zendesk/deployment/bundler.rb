# this is a stripped down version of https://github.com/carlhuda/bundler/blob/master/lib/bundler/deployment.rb
require 'zendesk_deployment'

module Zendesk::Deployment
  module Bundler
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :shared_path, :provided_by => :mirror_strategy
        required_variable :releases_path, :provided_by => :mirror_strategy
        required_variable :release_path, :provided_by => :mirror_strategy
        required_variable :current_path, :provided_by => :mirror_strategy
        required_variable :deploy_project_name, :provided_by => :environment_selector

        set_default :gemfile, 'Gemfile'
        set(:has_gemfile?) { gemfile && system("test -f #{gemfile}") }

        set_default :bundler_version, nil
        set(:bundler_command) { bundler_version ? "bundle _#{bundler_version}_" : 'bundle' }

        set_default(:bundles_path) { "#{shared_path}/bundles" }

        set(:rake) { has_gemfile? ? "#{bundler_command} exec rake" : 'rake' }

        set_default(:force_rebundle) { ENV["force_rebundle"] && !ENV["force_rebundle"].empty? || false }

        set_default(:bundle_command) { "cd #{release_path} && #{bundler_command} install --local --deployment --quiet --path vendor/bundle --without development test" }

        namespace :bundle do
          task :default, :except => { :no_release => true } do
            if has_gemfile?
              prepare_bundle_path = <<-SCRIPT
                set -e;

                if #{!!force_rebundle} || [ -f /etc/rebundle -o -f /etc/rebundle-#{deploy_project_name} -o ! -h #{current_path}/vendor/bundle ];
                then
                  NEW_BUNDLE_PATH="#{bundles_path}/#{Time.now.strftime('%Y%m%d-%H%M%S')}";
                  echo "Creating new bundle at $NEW_BUNDLE_PATH";
                  mkdir -p $NEW_BUNDLE_PATH;
                else
                  NEW_BUNDLE_PATH=`readlink #{current_path}/vendor/bundle`;
                fi;

                mkdir -p #{release_path}/vendor;
                rm -rf #{release_path}/vendor/bundle;
                ln -fs $NEW_BUNDLE_PATH #{release_path}/vendor/bundle;

                # Remove any bundles that don't correlate to a release, see :keep_releases in shared_git_strategy
                keep_these=`(find #{releases_path} -maxdepth 3 -type l -name 'bundle' -exec readlink {} \\; || echo "") | sort -u`;
                for bundle_name in #{bundles_path}/*;
                do
                  echo $keep_these | grep -F $bundle_name > /dev/null || (echo "Removing old bundle at $bundle_name" && rm -rf $bundle_name);
                done;
              SCRIPT

              run(prepare_bundle_path)

              rubies = fetch(:ruby_versions, [])

              if rubies.empty?
                logger.debug("Bundling")
                run bundle_command
              else
                rubies.each do |ruby|
                  logger.info("Bundling on #{ruby}")
                  logger.debug("Will run: #{bundle_command}")
                  run bundle_command, :ruby => ruby
                end
              end
            end
          end

          task :package do
            if has_gemfile?
              bundle_command = "bundle package --all"
              rubies = fetch(:ruby_versions, [])

              # temporary until everything is localized
              ::Bundler.with_clean_env do
                if rubies.empty?
                  logger.info("Bundling")
                  run_locally bundle_command
                else
                  rubies.each do |ruby|
                    logger.info("Bundling on #{ruby}")

                    cmd = <<-G
                      unset PATH
                      unset GEM_HOME
                      source /etc/environment
                      source /etc/profile
                      # development:
                      # source /opt/boxen/env.d/30_ruby.sh
                      export RBENV_VERSION=#{ruby}
                      #{bundle_command}
                    G

                    run_locally cmd
                  end
                end
              end

              extra_paths.push('vendor/cache/')
            end
          end

          desc 'Show the ruby gems currently used'
          task :list, :except => { :no_release => true } do
            puts capture("cd #{current_path} && bundle list")
          end
        end

        after 'deploy:prepare_project', 'bundle:package'
        after 'deploy:fetch_archive_from_mirror', 'bundle'
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Bundler)
  end
end
