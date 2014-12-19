require 'highline'
require 'capistrano/cli'

module Zendesk::Deployment
  module Utils
    def self.extended(config)
      config.load do
        set_default(:interactive?) { Capistrano::CLI.ui.instance_variable_get(:@input).tty? }
      end
    end

    def required_variable(name, options = {})
      return if exists?(name)

      if options[:provided_by]
        description = "Please set the :#{name} variable. Probably with the #{options[:provided_by]} module"
      else
        example_value = options[:value] || 'foo'
        description = "Please set the :#{name} variable. set :#{name}, #{example_value.inspect}"
      end

      set(name) { raise description }
    end

    def set_default(name, *args, &block)
      return if exists?(name)

      set(name, *args, &block)
    end

    def confirm(what, question = 'Are you sure?')
      return if !interactive?
      abort unless Capistrano::CLI.ui.agree("#{what}. #{question}")
    end

    def ask(question, answer_type = String, &block)
      question = HighLine::String.new(question).black.on_white
      Capistrano::CLI.ui.ask(question, answer_type, &block)
    end

    def abort(msg = nil)
      logger.important HighLine::String.new(msg).white.on_red if msg
      super()
    end

    # We don't include capistrano/deploy
    # so let's define run_locally here
    # https://github.com/capistrano/capistrano/blob/legacy-v2/lib/capistrano/recipes/deploy.rb#L131
    def run_locally(cmd, options = {})
      if dry_run
        return logger.debug "executing locally: #{cmd.inspect}"
      end

      logger.trace "executing locally: #{cmd.inspect}" if logger
      output_on_stdout = nil

      elapsed = Benchmark.realtime do
        output_on_stdout = `#{cmd}`
      end

      unless $?.success?
        raise Capistrano::LocalArgumentError, "Command #{cmd} returned status code #{$?}:\n#{output_on_stdout}"
      end
      logger.trace "command finished in #{(elapsed * 1000).round}ms" if logger

      output_on_stdout
    end
  end
end
