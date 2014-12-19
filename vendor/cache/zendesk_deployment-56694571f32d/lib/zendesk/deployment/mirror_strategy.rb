require 'capistrano/recipes/deploy/scm/git'
require 'tmpdir'

require 'zendesk/deployment/tags'
require 'zendesk/deployment/utils'

module Zendesk::Deployment
  module MirrorStrategy
    def self.extended(config)
      config.extend(Utils)
      config.extend(Tags)

      config.load do
        required_variable :application
        required_variable :repository
        required_variable :user

        role :deploy_mirror, :no_release => true do
          discover_mirrors('deploy_mirror')
        end

        # used by NewRelic
        set(:scm)                         { :git }

        set(:deploy_to)                   { File.join('/data', application) }

        set(:log_path)                    { File.join(deploy_to, 'log') }
        set(:current_path)                { File.join(deploy_to, 'current') }
        set(:releases_path)               { File.join(deploy_to, 'releases') }
        set(:shared_path)                 { File.join(deploy_to, 'shared') }

        set(:release_name)                { "#{Time.now.strftime('%Y%m%d-%H%M%S')}-#{real_revision[0...7]}" }
        set(:release_path)                { File.join(releases_path, release_name) }

        set(:log_symlink_target)          { File.join(release_path, 'log') }

        set(:archive_cache_path)          { File.join(shared_path, 'archives') }

        set(:mirror_dir)                  { File.join('/data/deploy', application) }

        set(:build_path)                  { Dir.mktmpdir }

        set(:archive_filename)            { "#{application}-#{real_revision}.tar" }
        set(:archive_path)                { File.join(build_path, archive_filename) }

        set(:compressed_filename)         { "#{archive_filename}.bz2" }
        set(:compressed_path)             { File.join(build_path, compressed_filename) }

        set_default(:compression_command) { 'pbzip2' }

        set(:checksum_filename)           { "#{compressed_filename}.sha1" }
        set(:checksum_path)               { File.join(build_path, checksum_filename) }

        set(:source)                      { Capistrano::Deploy::SCM::Git.new(self) }
        set(:real_revision)               { source.local.query_revision(revision) { |cmd| run_locally(cmd) } }
        set(:tag)                         { ENV['TAG'] }
        set(:revision)                    { tag || fetch(:branch, nil) || local_head_revision }
        set(:local_head_revision)         { `git rev-parse HEAD 2>&-`.strip }
        set(:local_head_tag)              { `git describe --exact-match HEAD 2>&-`.strip }
        set(:current_revision)            { capture("cat #{current_path}/REVISION 2>&- || true").strip }

        set_default(:extra_paths)         { [] }
        set_default(:exclude_paths)       { [] }

        set(:mirrored_app_bundle_uri) {
          "ftp://deploy_mirror@mirror/#{application}/#{compressed_filename}"
        }

        set_default(:fetch_retries)       { 5 }
        set_default(:fetch_retry_delay)   { 15 }

        set(:fetch_release_ftp) {
          "curl -sS --retry #{fetch_retries} --retry-delay #{fetch_retry_delay} -o #{archive_cache_path}/#{compressed_filename} #{mirrored_app_bundle_uri}"
        }

        set(:releases)                    { capture("ls -1t #{releases_path}").strip.split }
        set_default(:keep_releases)       { 5 }

        namespace :deploy do
          desc 'Builds your project'
          task :build do
            prepare_project
            build_archive
            archive_extra_paths
            compress_archive
            upload_archive
          end

          desc 'Releases your project'
          task :release do
            setup

            verify_archive
            fetch_archive_from_mirror

            transaction do
              create_symlink
              restart
            end

            cleanup
          end

          desc 'Builds and releases your project'
          task :default do
            build
            release
          end

          task :prepare_project do
          end

          task :build_archive do
            logger.debug "Archiving current code"
            run_locally "git archive HEAD > #{archive_path}"
          end

          task :archive_extra_paths do
            if extra_paths.any?
              logger.info "Archiving extra paths"
              logger.debug "Extra paths: #{extra_paths.inspect}"
              exclusion = exclude_paths.map { |directive| "--exclude=#{directive.shellescape}" }.join(' ')
              run_locally "tar #{exclusion} --dereference --exclude-vcs -rf #{archive_path} #{extra_paths.shelljoin}"
            end
          end

          task :compress_archive do
            logger.info "Compressing archive"
            run_locally "#{compression_command} #{archive_path}"
            run_locally "cd #{build_path} && sha1sum #{compressed_filename} > #{checksum_path}"
          end

          task :upload_archive do
            logger.info "Uploading release to mirrors"

            run "mkdir -p #{mirror_dir}", :roles => :deploy_mirror
            upload compressed_path, "#{mirror_dir}/#{compressed_filename}", :via => :scp, :roles => :deploy_mirror
            upload checksum_path, "#{mirror_dir}/#{checksum_filename}", :via => :scp, :roles => :deploy_mirror
          end

          task :verify_archive, :roles => :deploy_mirror do
            logger.info "Verifying archive"
            run %Q{test -f "#{mirror_dir}/#{compressed_filename}" && test -f "#{mirror_dir}/#{checksum_filename}"}
            run %Q{cd #{mirror_dir} && sha1sum --status -c #{checksum_filename} 2>&-}
          end

          task :fetch_archive_from_mirror, :except => { :no_release => true } do
            logger.info "Fetching archive from mirrors"
            run fetch_release_ftp

            logger.info "Unpacking archive"
            run "mkdir #{release_path}"

            compressed_path = File.join(archive_cache_path, compressed_filename)
            run "tar --use-compress-prog=#{compression_command} -xf #{compressed_path} -C #{release_path}"
            run "rm #{compressed_path}"
          end

          desc 'Prepares one or more servers for deployment.'
          task :setup, :except => { :no_release => true } do
            # create basic directories
            dirs = [deploy_to, releases_path, shared_path, log_path, archive_cache_path]

            logger.info 'Ensuring that the main directories are there'
            run "sudo install -d -m 0775 -o #{user} -g #{fetch(:group, user)} #{dirs.join(' ')}"
          end

          before 'deploy:fetch_archive_from_mirror' do
            logger.important "Deploying to #{release_path}"
          end

          after 'deploy:fetch_archive_from_mirror' do
            run "echo #{real_revision} > #{File.join(release_path, 'REVISION')}"
          end

          desc 'Update the symlink to the next deploy.'
          task :create_symlink, :except => { :no_release => true } do
            current_release_path = "(none)"

            begin
              current_release_path = capture("readlink #{current_path}").strip

              on_rollback do
                logger.important "Rolling back symlink to #{current_release_path}"
                run "ln -Tsf #{current_release_path} #{current_path}"
              end
            rescue Capistrano::CommandError
              logger.important "Could not find current release name, cannot fallback"
            end

            logger.info "Updating the symlink from #{current_release_path} to #{release_path}"
            run "ln -Tsf #{release_path} #{current_path}"
          end

          desc 'Clean up old releases'
          task :cleanup, :except => { :no_release => true } do
            current_release_name = capture("readlink #{current_path} || true").strip.split('/')[-1] || nil

            possible_deletions = releases - [release_name, current_release_name, 'alpha', 'omega']
            releases_to_delete = possible_deletions - possible_deletions.first(keep_releases)

            logger.info "Deleting these old releases: #{releases_to_delete.join(', ')}" if releases_to_delete.any?

            releases_to_delete.each do |release|
              path = File.join(releases_path, release)
              logger.debug "Deleting #{path}"

              run "rm -rf #{path}"
            end
          end
        end
      end
    end

    def mirror_host_filter(host, conf, tag)
      # Return true if host has correct tag and is in correct environment
      _, environment_group, _ = environment.to_s.match(/([^\d]+)(\d+)?/).to_a

      if environment_group == 'pod'
        environment_group = 'production'
      elsif environment_group == 'master'
        environment_group = 'staging'
      end

      conf['environment'] == environment_group &&
        Array(conf["tags"]).include?(tag)
    end

    def discover_mirrors(tag)
      found_servers = []

      environment_discovery.each_host_config do |host, conf|
        next unless mirror_host_filter(host, conf, tag)
        found_servers << host
      end

      if found_servers.any?
        logger.info "Found these servers for the #{tag} tag: #{found_servers.sort.join(', ')}"
      else
        logger.debug "No servers found for the #{tag} tag"
      end

      found_servers
    end

    Capistrano::Configuration.instance(:must_exist).extend(MirrorStrategy)
  end
end
