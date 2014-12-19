require 'zendesk_deployment'
require 'zendesk/deployment/full_log'

module Zendesk::Deployment
  module Notify
    class RevisionSet
      attr_accessor :repository, :previous, :current

      def initialize(repository, previous, current)
        self.repository = repository
        self.previous   = previous
        self.current    = current
      end

      def delta_url
        "#{public_git_url}/compare/#{map_sha_tag(previous)}...#{map_sha_tag(current)}"
      end

      def public_git_url
        repository.sub("git@github.com:","https://github.com/").sub(/\.git$/,'')
      end

      def map_sha_tag(revision)
        tag = %x(git show-ref | grep '^#{revision} refs/tags/' | cut -d/ -f3).chomp
        tag.empty? ? revision : tag
      end
    end

    class Message
      attr_accessor :deployer, :application, :environment, :rails_env, :revision_set, :deploy_log

      def initialize(args = {})
        self.deployer     = args.fetch(:deployer)
        self.application  = args.fetch(:application)
        self.environment  = args.fetch(:environment)
        self.rails_env    = args.fetch(:rails_env)
        self.revision_set = args.fetch(:revision_set)
        self.deploy_log   = args.fetch(:deploy_log)
      end

      def subject
        "[ZD DEPLOY] #{deployer} deployed #{application} to #{environment} (#{rails_env}): #{revision_set.current}"
      end

      def body
        @body ||= begin
          message = []
          message << "\n#{subject}"
          message << "\nSummary\n"
          message << revision_set.delta_url
          message << "\nLog\n"
          message << deploy_log
          message.join("\n")
        end
      end

      def path
        @path ||= File.join("/tmp", "deploy_notify_message_#{normalized_application}_#{Time.now.to_i}.log")
      end

      def normalized_application
        application.to_s.downcase.gsub(" ", "_")
      end
    end

    def self.extended(config)
      config.extend(Utils)

      config.load do
        required_variable :application
        required_variable :repository
        required_variable :deployer
        required_variable :revision,          :provided_by => :mirror_strategy
        required_variable :current_revision,  :provided_by => :mirror_strategy
        required_variable :environment,       :provided_by => :environment_selector
        required_variable :rails_env,         :provided_by => :environment_selector
        required_variable :deploy_host,       :provided_by => :environment_selector

        namespace :deploy do
          namespace :notify do
            task :default do
              email
            end

            task :email do
              next unless recipients.any?

              message = Message.new(
                :deployer     => deployer,
                :application  => application,
                :environment  => environment,
                :rails_env    => rails_env,
                :revision_set => RevisionSet.new(repository, current_revision, revision),
                :deploy_log   => full_log
              )

              put message.body, message.path, :hosts => deploy_host, :via => :scp
              run "cat #{message.path} | mail -s '#{message.subject}' #{recipients.join(" ")}", :hosts => deploy_host
              run "rm -f #{message.path}", :hosts => 'localhost'
            end

            def recipients
              @recipients ||= begin
                recs = fetch(:email_notification, [])
                recs = [recs] if recs.is_a?(String)
                recs.compact!
                recs
              end
            end
          end
        end

        after "deploy:release", "deploy:notify"
        # after "deploy:switch", "deploy:notify"
      end
    end

    Capistrano::Configuration.instance(:must_exist).extend(Notify)
  end
end
