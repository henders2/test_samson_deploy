require_relative 'helper'
require 'zendesk/deployment/bundler'

describe Zendesk::Deployment::Bundler do
  let(:deploy_to)     { Dir.mktmpdir }
  let(:releases_path) { File.join(deploy_to, 'releases') }
  let(:release_path)  { File.join(releases_path, 'new_release') }
  let(:shared_path)   { File.join(deploy_to, 'shared') }
  let(:current_path)  { File.join(deploy_to, 'current') }

  let(:new_bundle_path) { "#{cap.bundles_path}/#{Time.now.strftime('%Y%m%d-%H%M%S')}" }

  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::Bundler)

    FileUtils.mkdir_p(releases_path)
    FileUtils.mkdir_p(release_path)
    FileUtils.mkdir_p(shared_path)
    FileUtils.mkdir_p(current_path)

    FileUtils.touch(File.join(release_path, 'Gemfile'))

    # setup Gemfile.lock
    Bundler.with_clean_env do
      Dir.chdir(release_path) do
        `bundle --quiet`
      end
    end

    cap.set :ruby_versions, ['ree', '1.9.3']
    cap.set :deploy_project_name, 'deploy_project_name'
    cap.set :releases_path, releases_path
    cap.set :release_path, release_path
    cap.set :shared_path, shared_path
    cap.set :current_path, current_path

    cap.run_locally!
  end

  around do |test|
    Bundler.with_clean_env(&test)
  end

  def must_have_bundled_into(path)
    File.readlink(File.join(release_path, 'vendor', 'bundle')).must_equal path
    cap.ruby_versions.each do |ruby|
      cap.must_have_run("cd #{release_path} && bundle install --local --deployment --quiet --path vendor/bundle --without development test", :ruby => ruby)
    end
  end

  describe 'deploy:fetch_archive_from_mirror' do
    before do
      cap.find_and_execute_task('deploy:fetch_archive_from_mirror')
    end

    it 'should bundle' do
      cap.must_have_invoked 'bundle'
    end
  end

  describe 'deploy:prepare_project' do
    before do
      cap.set :ruby_versions, []
      cap.find_and_execute_task('deploy:prepare_project')
    end

    it 'should bundle' do
      cap.must_have_invoked 'bundle:package'
    end

    it 'should add extra_paths' do
      cap.extra_paths.must_equal ['vendor/cache/']
    end
  end

  describe 'force_rebundle' do
    before { ENV.delete('force_rebundle') }
    after  { ENV.delete('force_rebundle') }

    it 'defaults to false' do
      cap.force_rebundle.must_equal false
    end

    it 'is true if the environment variable force_rebundle is present' do
      ENV['force_rebundle'] = 'foo'
      cap.force_rebundle.must_equal true
    end

    it 'is false if the environment variable force_rebundle is empty' do
      ENV['force_rebundle'] = ''
      cap.force_rebundle.must_equal false
    end
  end

  describe 'when there is a Gemfile' do
    describe 'bundle' do
      describe 'when the logger level is debug' do
        before do
          cap.logger.level = Logger::DEBUG
        end

        it 'must modify the bundle action' do
          cap.find_and_execute_task('bundle')
          cap.must_have_run("cd #{release_path} && bundle install --local --deployment --quiet --path vendor/bundle --without development test", :ruby => '1.9.3')
        end
      end

      describe 'when the previous release has a bundle' do
        describe 'when not force_rebundle' do
          let(:old_bundle_path) { File.join(cap.bundles_path, 'old')}

          before do
            cap.set :force_rebundle, false
            FileUtils.mkdir_p(old_bundle_path)
            FileUtils.mkdir_p(File.join(current_path, 'vendor'))
            FileUtils.symlink(old_bundle_path, File.join(current_path, 'vendor', 'bundle'))
          end

          it 'must reuse the previous bundle' do
            cap.find_and_execute_task('bundle')
            must_have_bundled_into(old_bundle_path)
          end
        end

        describe 'when force_rebundle' do
          before { cap.set :force_rebundle, true }
          it 'must create a new bundle' do
            cap.find_and_execute_task('bundle')
            must_have_bundled_into(new_bundle_path)
          end
        end
      end

      describe 'when there is no previous release' do
        before { cap.set :force_rebundle, false }
        it 'must create a new bundle' do
          cap.find_and_execute_task('bundle')
          must_have_bundled_into(new_bundle_path)
        end
      end

      it 'deletes unused bundles' do
        bundle_1 = File.join(cap.bundles_path, 'bundle_1') # unused
        bundle_2 = File.join(cap.bundles_path, 'bundle_2') # used by release_1 and release_2
        bundle_3 = File.join(cap.bundles_path, 'bundle_3') # used by release_3

        FileUtils.mkdir_p(bundle_1)
        FileUtils.mkdir_p(bundle_2)
        FileUtils.mkdir_p(bundle_3)

        # symlink release_1 to bundle_2
        FileUtils.mkdir_p(File.join(cap.releases_path, 'release_1', 'vendor'))
        FileUtils.symlink(bundle_2, File.join(cap.releases_path, 'release_1', 'vendor', 'bundle'))

        # symlink release_2 to bundle_2
        FileUtils.mkdir_p(File.join(cap.releases_path, 'release_2', 'vendor'))
        FileUtils.symlink(bundle_2, File.join(cap.releases_path, 'release_2', 'vendor', 'bundle'))

        # symlink release_3 to bundle_3
        FileUtils.mkdir_p(File.join(cap.releases_path, 'release_3', 'vendor'))
        FileUtils.symlink(bundle_3, File.join(cap.releases_path, 'release_3', 'vendor', 'bundle'))

        cap.find_and_execute_task('bundle')

        assert !File.directory?(bundle_1), "#{bundle_1} should be deleted"
        assert File.directory?(bundle_2), "#{bundle_2} should not be deleted"
        assert File.directory?(bundle_3), "#{bundle_3} should not be deleted"
      end
    end

    it 'sets the rake command to use bundle exec' do
      cap.rake.must_equal 'bundle exec rake'
    end
  end

  describe 'when there is no Gemfile' do
    before { FileUtils.rm_f(File.join(release_path, 'Gemfile')) }

    describe 'bundle' do
      before do
        Dir.chdir(release_path) { cap.find_and_execute_task('bundle') }
      end

      it 'should not bundle' do
        cap.ruby_versions.each do |ruby|
          cap.wont_have_run(@bundle_command, :ruby => ruby)
        end
      end
    end

    describe 'bundle:package' do
      before do
        Dir.chdir(release_path) { cap.find_and_execute_task('bundle:package') }
      end

      it 'should not bundle' do
        cap.ruby_versions.each do |ruby|
          cap.wont_have_run('bundle package')
        end
      end
    end

    it 'sets the rake command to not use bundle exec' do
      Dir.chdir(release_path) { cap.rake.must_equal 'rake' }
    end
  end

  describe 'bundler_version' do
    before { cap.set(:bundler_version, '1.7.4') }

    it 'must modify the rake command' do
      cap.rake.must_equal 'bundle _1.7.4_ exec rake'
    end

    it 'must modify the bundle action' do
      cap.find_and_execute_task('bundle')
      cap.must_have_run("cd #{release_path} && bundle _1.7.4_ install --local --deployment --quiet --path vendor/bundle --without development test", :ruby => '1.9.3')
      cap.must_have_run("cd #{release_path} && bundle _1.7.4_ install --local --deployment --quiet --path vendor/bundle --without development test", :ruby => 'ree')
    end
  end
end
