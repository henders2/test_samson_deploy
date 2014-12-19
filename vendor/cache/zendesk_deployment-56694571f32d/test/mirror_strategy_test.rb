require_relative 'helper'

require 'zendesk/deployment/mirror_strategy'

require 'tmpdir'
require 'fileutils'
require 'tempfile'

describe Zendesk::Deployment::MirrorStrategy do
  before do
    cap.extend(Zendesk::Deployment::MirrorStrategy)

    @pwd = FileUtils.pwd
    FileUtils.cd($test_repository)

    cap.set :application, 'test_app'
    cap.set :repository,  'file://' + $test_repository
    cap.set :deploy_to, Dir.mktmpdir
    cap.set :user,      Process.uid
    cap.set :group,     Process.gid
    cap.set :compression_command, 'bzip2'

    cap.namespace :deploy do
      task :restart do
      end
    end
  end

  after do
    FileUtils.cd(@pwd)
    FileUtils.rm_rf(cap.deploy_to)
  end

  describe 'release_path' do
    it 'is the path to the current revision' do
      cap.release_path.must_equal File.join(cap.releases_path, cap.release_name)
    end
  end

  describe 'revision variables' do
    before do
      current = File.join(cap.releases_path, 'abc123')
      FileUtils.mkdir_p(current)

      File.open(File.join(current, 'REVISION'), 'w') { |f| f.puts('alpha_revision') }

      FileUtils.symlink(current, cap.current_path)

      cap.run_locally!
    end

    describe 'current_revision' do
      it 'is the contents of the REVISION file in the active release' do
        cap.current_revision.must_equal 'alpha_revision'
      end
    end
  end

  describe 'deploy:setup' do
    before do
      cap.run_locally!
      cap.find_and_execute_task('deploy:setup')
    end

    it 'creates directories with the right permissions' do
      directories = [
        cap.deploy_to,
        File.join(cap.deploy_to, 'releases'),
        File.join(cap.deploy_to, 'shared', 'archives'),
        File.join(cap.deploy_to, 'log')
      ]

      directories.each do |directory|
        File.directory?(directory).must_equal true,    "#{directory} is not a directory"
        File.stat(directory).uid.must_equal cap.user,  "#{directory} is not owned by the user"
        File.stat(directory).gid.must_equal cap.group, "#{directory} is not owned by the group"
      end
    end

    it 'is non-destructive' do
      alpha_file = File.join(cap.deploy_to, 'releases', 'alpha_file')

      `touch #{alpha_file}`

      cap.find_and_execute_task('deploy:setup')

      File.exist?(alpha_file).must_equal true
    end
  end

  describe 'deploy archive building' do
    before do
      cap.run_locally!
      cap.set(:release_path) { $test_repository }
      cap.find_and_execute_task('deploy:setup')

      Dir.chdir(cap.release_path) do
        system('git checkout v0.1.1 2>&-')
      end
    end

    describe 'deploy:build_archive' do
      let(:compressed_files) { `tar -tf #{cap.archive_path}`.split("\n") }

      before do
        Dir.chdir(cap.release_path) do
          cap.find_and_execute_task('deploy:build_archive')
        end
      end

      it 'properly handles git HEAD' do
        assert_equal %w{file_a file_b}, compressed_files
      end
    end

    describe 'deploy:archive_extra_paths' do
      let(:extra_paths) { [] }
      let(:compressed_files) { `tar -tf #{cap.archive_path}`.split("\n") }

      before do
        cap.set(:extra_paths) { extra_paths }

        Dir.chdir(cap.release_path) do
          cap.find_and_execute_task('deploy:build_archive')
          cap.find_and_execute_task('deploy:archive_extra_paths')
        end
      end

      it 'adds no extra paths' do
        assert_equal %w{file_a file_b}, compressed_files
      end

      describe 'extra paths' do
        let(:file) { Tempfile.new('test file with spaces', $test_repository) }
        let(:filename) { File.basename(file.path) }
        let(:extra_paths) { [filename] }

        it 'adds the extra path' do
          assert_includes compressed_files, filename
        end
      end

      describe 'symlinked extra path' do
        let(:file) { Tempfile.new('test file with spaces', full_dir) }

        let(:full_dir) do
          File.join($test_repository, 'test-dir').tap do |dir|
            FileUtils.mkdir_p(dir)
          end
        end

        let(:symlink_dir) do
          File.join($test_repository, 'sym-dir').tap do |dir|
            FileUtils.ln_s(full_dir, dir)
          end
        end

        let(:filename) { File.join('sym-dir', File.basename(file.path)) }
        let(:extra_paths) do
          filename # create the test file

          [File.basename(symlink_dir)]
        end

        it 'adds the extra path' do
          assert_includes compressed_files, filename
        end
      end
    end

    describe 'deploy:compress_archive' do
      let(:compressed_files) { `tar -tjf #{cap.compressed_path}`.split("\n") }

      before do
        Dir.chdir(cap.release_path) do
          cap.find_and_execute_task('deploy:build_archive')
          cap.find_and_execute_task('deploy:archive_extra_paths')
          cap.find_and_execute_task('deploy:compress_archive')
        end
      end

      it 'properly handles git HEAD' do
        assert_equal %w{file_a file_b}, compressed_files
      end
    end
  end

  describe 'deploy:build' do
    let(:extra_paths) { [] }
    let(:exclude_paths) { [] }
    let(:compressed_files) { `tar -tjf #{cap.compressed_path}`.split("\n") }

    before do
      cap.run_locally!
      cap.set(:mirror_dir) { Dir.mktmpdir }
      cap.set(:extra_paths) { extra_paths }
      cap.set(:exclude_paths) { exclude_paths }
      cap.find_and_execute_task('deploy:setup')

      Dir.chdir($test_repository) do
        system('git checkout v1.0.1-annotated 2>&-')
        FileUtils.touch('Gemfile')
        cap.find_and_execute_task('deploy:build')
      end
    end

    it 'creates a tar.bz2' do
      assert File.exist?(cap.compressed_path)
    end

    it 'adds the repo files' do
      ('a'..'e').each do |c|
        assert_includes compressed_files, "file_#{c}"
      end
    end

    it 'creates a proper checksum' do
      assert File.exist?(cap.checksum_path)
      assert system(%Q{cd #{cap.build_path} && sha1sum --status -c #{cap.checksum_filename}})
    end

    it 'uploads the tar.bz2 to the mirror' do
      assert File.exist?(File.join(cap.mirror_dir, cap.compressed_filename))
      assert File.exist?(File.join(cap.mirror_dir, cap.checksum_filename))
    end

    describe 'exclude paths' do
      let(:full_path) { FileUtils.mkdir_p(File.join($test_repository, 'test-dir')) }
      let(:directory) { full_path; 'test-dir/' }

      let(:file) { Tempfile.new('test file with spaces', File.join($test_repository, directory)) }
      let(:filename) { File.join(directory, File.basename(file)) }

      let(:extra_paths) { [directory] }
      let(:exclude_paths) { [filename] }

      it 'adds the extra path' do
        assert_includes compressed_files, directory
      end

      it 'does not add the excluded path' do
        refute_includes compressed_files, exclude_paths.first
      end
    end

    describe 'extra paths' do
      let(:file) { Tempfile.new('test file with spaces', $test_repository) }
      let(:filename) { File.basename(file.path) }
      let(:extra_paths) { [filename] }

      it 'adds the extra path' do
        assert_includes compressed_files, filename
      end
    end
  end

  describe 'deploy:verify_archive' do
    before do
      cap.run_locally!

      cap.set(:mirror_dir) { Dir.mktmpdir }
      cap.find_and_execute_task('deploy:setup')

      Dir.chdir($test_repository) do
        FileUtils.touch('Gemfile')
        cap.find_and_execute_task('deploy:build')
      end
    end

    it 'works with a valid checksum' do
      assert cap.find_and_execute_task('deploy:verify_archive')
    end

    it 'fails with an invalid checksum' do
      File.write(File.join(cap.mirror_dir, cap.checksum_filename), "123123123 #{cap.compressed_filename}")

      assert_raises Capistrano::CommandError do
        cap.find_and_execute_task('deploy:verify_archive')
      end
    end

    it 'fails without a compressed file' do
      File.unlink(File.join(cap.mirror_dir, cap.compressed_filename))

      assert_raises Capistrano::CommandError do
        cap.find_and_execute_task('deploy:verify_archive')
      end
    end

    it 'fails without a checksum file' do
      File.unlink(File.join(cap.mirror_dir, cap.checksum_filename))

      assert_raises Capistrano::CommandError do
        cap.find_and_execute_task('deploy:verify_archive')
      end
    end
  end

  describe 'deploy:fetch_archive_from_mirror' do
    let(:archive_path) { File.join(cap.archive_cache_path, cap.compressed_filename) }

    before do
      cap.run_locally!

      cap.set(:mirror_dir) { Dir.mktmpdir }

      cap.find_and_execute_task('deploy:setup')

      Dir.chdir($test_repository) do
        system('git checkout v1.0.1-annotated 2>&-')
        FileUtils.touch('Gemfile')
        cap.find_and_execute_task('deploy:build')
      end

      cap.set(:fetch_release_ftp) do
        "mv #{cap.compressed_path} #{archive_path}"
      end

      cap.find_and_execute_task('deploy:fetch_archive_from_mirror')
    end

    it 'creates the release path' do
      assert Dir.exist?(cap.release_path)
    end

    it 'removes the archive' do
      assert !File.exist?(archive_path)
    end

    it 'adds the repo files' do
      ('a'..'e').each do |c|
        assert File.exist?(File.join(cap.release_path, "file_#{c}"))
      end
    end
  end

  describe 'deploy' do
    before do
      cap.run_locally!

      cap.set(:production?, false)
      cap.set(:mirror_dir) { Dir.mktmpdir }
      cap.set(:fetch_release_ftp) do
        "mv #{cap.compressed_path} #{File.join(cap.archive_cache_path, cap.compressed_filename)}"
      end

      Dir.chdir($test_repository) do
        system('git checkout v1.0.1-annotated 2>&-')
        FileUtils.touch('Gemfile')
        cap.find_and_execute_task('deploy')
      end
    end

    it 'creates the correct symlinked repo' do
      ('a'..'e').each do |c|
        assert File.exist?(File.join(cap.current_path, "file_#{c}"))
      end
    end

    it 'must have run deploy:restart' do
      cap.must_have_invoked('deploy:restart')
    end

    it 'must have run deploy:cleanup' do
      cap.must_have_invoked('deploy:cleanup')
    end
  end

  describe 'deploy:cleanup' do
    let(:previous_release) { File.join(cap.releases_path, 'previous_release') }

    before do
      cap.run_locally!

      cap.set(:mirror_dir) { Dir.mktmpdir }
      cap.find_and_execute_task('deploy:setup')

      6.times do |i|
        created_at = Time.now - (i * 60)
        release = File.join(cap.releases_path, "release#{i}")
        Dir.mkdir(release)
        FileUtils.touch(release, :mtime => created_at)
      end

      Dir.mkdir(previous_release)
      `ln -Tsf #{previous_release} #{cap.current_path}`

      Dir.mkdir(cap.release_path)

      cap.find_and_execute_task('deploy:cleanup')
    end

    it 'cleans up all but 5 releases by date' do
      skip "doesn't work on travis yet" if ENV['TRAVIS']

      directories = Dir.glob(File.join(cap.releases_path, 'release*'))
      directories.size.must_equal 5
      File.basename(directories.last).must_equal 'release4'
      # i.e. we removed the one created last (release5)
    end

    it 'keeps the previous release' do
      assert Dir.exist?(previous_release)
    end

    it 'keeps the current release' do
      assert Dir.exist?(cap.release_path)
    end
  end
end
