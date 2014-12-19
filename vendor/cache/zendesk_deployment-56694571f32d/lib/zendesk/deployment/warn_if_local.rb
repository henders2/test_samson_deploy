require 'zendesk_deployment'

module Zendesk::Deployment
  module WarnIfLocal
    def self.extended(config)
      config.load do
        set(:repository_is_dirty?) { system('test -n "$(git status --porcelain --untracked-files no)"') }

        task :abort_if_local do
          if fetch(:gateway, nil) && gateway !~ /aws\d+\.zdsystest\.com$/
            abort([
              "Local #{application} deploys are not safe.",
              "Please ssh to #{gateway} and run your deploy from there."
            ].join("\n"))
          end

          if repository_is_dirty?
            confirm("Your local git repository is dirty. You could be deploying bad code", "Do you want to continue?")
          end
        end

        before 'deploy:build', 'abort_if_local'
        before 'deploy:release', 'abort_if_local'
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(WarnIfLocal)
  end
end
