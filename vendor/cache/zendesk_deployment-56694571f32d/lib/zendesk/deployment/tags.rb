require 'zendesk_deployment'
require 'zendesk/deployment/committish'

module Zendesk::Deployment
  module Tags
    def committish_from(dir)
      sha = capture("cd #{dir} && cat REVISION 2>&- || true")
      Committish.new(sha)
    end

    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :environment,           :provided_by => :environment_selector
        required_variable :production?,           :provided_by => :environment_selector
        required_variable :gamma?,                :provided_by => :environment_selector
        required_variable :tag,                   :provided_by => :mirror_strategy
        required_variable :revision,              :provided_by => :mirror_strategy
        required_variable :current_revision,      :provided_by => :mirror_strategy
        required_variable :previous_revision,     :provided_by => :mirror_strategy

        set_default :confirm_minor_releases?, true
        set_default(:require_tag?) { production? && !gamma? }

        set(:committish)          { Committish.new(revision) }
        set(:current_committish)  { Committish.new(current_revision) }
        set(:previous_committish) { Committish.new(previous_revision) }


        namespace :tags do
          desc 'show the tags of the two deploy locations'
          task :default do
            current_committish && previous_committish # just to preload the values for prettier output
            current
            previous
          end

          task :current do
            description = current_committish ? current_committish.describe : '(unknown)'
            logger.important "Currently deployed:  #{description}"
          end

          task :previous do
            description = previous_committish ? previous_committish.describe : '(unknown)'
            logger.important "Previously deployed: #{description}"
          end
        end

        before 'deploy:release' do
          if require_tag?
            unless tag && committish.valid_tag?
              msg = [
                "You need to specify a tag when deploying to #{environment}",
                "Example:",
                "   bundle exec cap #{environment} deploy TAG=v2.56.2"
              ]
              abort(msg.join("\n"))
            end
          end
        end

        before 'deploy:release' do
          if committish.valid_tag? && current_committish.valid_tag?
            if committish < current_committish
              confirm("You are deploying #{committish} which is older than #{current_committish}")
            elsif confirm_minor_releases? && !committish.same_minor?(current_committish)
              confirm("You are deploying a new minor release (#{committish}). Current version #{current_committish}")
            end
          end
        end
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Tags)
  end
end
