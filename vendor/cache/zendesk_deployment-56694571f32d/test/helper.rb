require 'bundler/setup'

begin
  require 'byebug'
rescue LoadError
end

require 'zendesk_deployment'
require 'capistrano'

require 'timecop'

require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/around'

require 'tmpdir'
require 'fileutils'

$test_repository = Dir.mktmpdir
$test_repository_tags = {}

FileUtils.cd($test_repository) do
  `git init`

  `touch file_a && git add file_a && git commit -m 'first'  && git tag v0.1.0`
  $test_repository_tags['v0.1.0'] = `git rev-parse HEAD 2>&-`.strip

  `touch file_b && git add file_b && git commit -m 'second' && git tag v0.1.1`
  $test_repository_tags['v0.1.1'] = `git rev-parse HEAD 2>&-`.strip

  `touch file_c && git add file_c && git commit -m 'third'  && git tag v0.2.0`
  $test_repository_tags['v0.2.0'] = `git rev-parse HEAD 2>&-`.strip

  `touch file_d && git add file_d && git commit -m 'fourth' && git tag v1.0.0`
  $test_repository_tags['v1.0.0'] = `git rev-parse HEAD 2>&-`.strip

  `touch file_e && git add file_e && git commit -m 'fifth' && git tag -a v1.0.1-annotated -m 'my version 1.0.1'`
  $test_repository_tags['v1.0.1-annotated'] = `git rev-parse HEAD 2>&-`.strip
end

$test_repository_tags.freeze

module EmptyDeploy
  def self.extended(config)
    config.load do
      set(:releases_path) { File.join(deploy_to, 'releases') }
      set(:extra_paths) { [] }

      namespace :deploy do
        task :default do
          build
          release
        end

        task :setup, :except => { :no_release => true } do
        end

        task :build do
          prepare_project
        end

        task :prepare_project do
        end

        task :release do
          fetch_archive_from_mirror

          transaction do
            create_symlink
          end
        end

        task :fetch_archive_from_mirror, :except => { :no_release => true } do
        end

        task :create_symlink, :except => { :no_release => true } do
        end

        task :restart, :except => { :no_release => true } do
        end
      end
    end
  end
end

Capistrano::Configuration.class_eval do
  def run_locally!
    @run_locally = true
  end

  def run(cmd, options = {}, &block)
    runs << { :command => cmd, :options => options }
    if @run_locally
      output = `#{cmd.sub(/^sudo /, '')}`
      unless $?.success?
        abort "failed: #{output}"
        raise Capistrano::CommandError, "failed: #{output}"
      end
      block.call({:host => "localhost"}, :out, output) if block
      output
    end
  end

  def runs
    @runs ||= []
  end

  def must_have_run(cmd, options = {})
    runs.must_include :command => cmd, :options => options
  end

  def wont_have_run(cmd, options = {})
    runs.wont_include :command => cmd, :options => options
  end

  def put(data, path, options = {})
    puts << { :data => data, :path => path, :options => options }

    if @run_locally
      File.open(path, 'w') do |f|
        f.write(data)
      end
    end
  end

  def upload(from, to, options={}, &block)
    mode = options.delete(:mode)

    if @run_locally
      FileUtils.cp_r(from, to)
    end

    if mode
      mode = mode.is_a?(Numeric) ? mode.to_s(8) : mode.to_s
      File.chmod mode, to, options
    end
  end

  def puts
    @puts ||= []
  end

  alias_method :invoke_task_directly_without_tracking, :invoke_task_directly
  def invoke_task_directly(task)
    invoked_tasks << task.fully_qualified_name
    invoke_task_directly_without_tracking(task)
  end

  def invoked_tasks
    @invoked_tasks ||= []
  end

  def must_have_invoked(*task_names)
    (invoked_tasks & task_names).must_equal task_names
  end

  def wont_have_invoked(*task_names)
    (invoked_tasks & task_names).must_be_empty
  end

  def abort(msg = nil)
    @aborted = true
  end

  def aborted?
    @aborted ||= false
  end
end

Object.class_eval do
  def abort(msg = nil)
    Capistrano::Configuration.instance.abort(msg)
  end
end

Capistrano::Configuration.instance = Capistrano::Configuration.new
require 'zendesk/deployment/full_log'

MiniTest::Spec.class_eval do
  def cap
    Capistrano::Configuration.instance
  end

  before do
    Timecop.freeze
    instance = Capistrano::Configuration.new
    instance.extend(Zendesk::Deployment::FullLog)
    instance.logger.level = -1 # disable logging in tests
    Capistrano::Configuration.instance = instance
  end

  after do
    Timecop.return
  end
end
