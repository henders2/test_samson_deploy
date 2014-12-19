require 'zendesk_deployment'

module Zendesk::Deployment
  module CodeChanges
    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :revision, :provided_by => :mirror_strategy
        required_variable :current_revision, :provided_by => :mirror_strategy
      end
    end

    # helper method to speed up deploys by avoiding precompile
    # try to sync over old assets if they did not change or execute block
    #
    # on_outdated_assets do
    #  run "rake assets:precompile"
    # end
    def on_outdated_assets
      if changes_in?("Gemfile", "Gemfile.lock", "vendor/assets", "app/assets", "lib/assets") || !sync_from_last_release("public/assets")
        yield
      end
    end

    # changes to last release (in other folder: alpha -> omega)
    def changes_in?(*files)
      changed_files = `git diff --name-only #{current_revision} #{revision}`.split

      unless $?.success?
        $stderr.puts "git diff failed, assuming changed."
        return true
      end

      changed_files.any? { |c| files.any? { |f| c.start_with?(f) } }
    end

    private

    def sync_from_last_release(folder)
      return unless current_path

      source = "#{current_path}/#{folder}"
      target = "#{release_path}/#{folder}"

      run_success?("test -d #{source} && grep #{current_revision} #{current_path}/REVISION && rsync -a #{source}/. #{target}")
    end

    def run_success?(command)
      run command
    rescue Capistrano::CommandError
      false
    else
      true
    end

    Capistrano::Configuration.instance(:must_exist).extend(CodeChanges)
  end
end
