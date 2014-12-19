require_relative 'helper'
require 'zendesk/deployment/migrations'

describe Zendesk::Deployment::Migrations do
  before do
    cap.extend(EmptyDeploy)
    cap.extend(Zendesk::Deployment::Migrations)

    cap.set :rake, 'rake'
    cap.set :production?, false
    cap.set :current_revision, 'HEAD^'
    cap.set :revision, 'HEAD'

    cap.run_locally!
  end

  describe 'deploy:release' do
    describe 'not in production' do
      before do
        cap.set :release_path, File.expand_path('release_without_pending_migrations', File.dirname(__FILE__))
        cap.find_and_execute_task 'deploy:release'
      end

      it 'should execute migrate' do
        cap.must_have_invoked 'deploy:migrate'
      end
    end

    describe 'in production' do
      before do
        cap.set :production?, true
      end

      describe 'when there are no pending migrations' do
        before do
          cap.set :release_path, File.expand_path('release_without_pending_migrations', File.dirname(__FILE__))
          cap.find_and_execute_task 'deploy:release'
        end

        it 'should not abort' do
          cap.aborted?.must_equal false
        end
      end

      describe 'when there are pending migrations' do
        before do
          cap.set :release_path, File.expand_path('release_with_pending_migrations', File.dirname(__FILE__))
          cap.find_and_execute_task 'deploy:release'
        end

        it 'should abort' do
          cap.aborted?.must_equal true
        end

        it 'should not run migrations' do
          cap.wont_have_invoked 'deploy:migrate'
        end
      end

      describe 'when there are pending migrations and rake fails' do
        before do
          cap.set :release_path, File.expand_path('release_with_rake_error', File.dirname(__FILE__))
          cap.find_and_execute_task 'deploy:release'
        end

        it 'should have aborted' do
          cap.aborted?.must_equal true
        end
      end
    end

    describe 'deploy:migrate' do
      before do
        cap.set :release_path, File.expand_path('release_with_pending_migrations', File.dirname(__FILE__))
      end

      describe 'when the files have changed' do
        before do
          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              FileUtils.mkdir_p("db/migrate")
              File.write("db/migrate/test.file", "test")
              `git init 2>&1 && git add . 2>&1 && git commit -am 'a' 2>&1`
              File.write("db/migrate/test.file", "hello")
              `git commit -am 'a2' 2>&1`
              cap.find_and_execute_task 'deploy:migrate'
            end
          end
        end

        it 'should migrate the database' do
          cap.must_have_run "cd #{cap.release_path} && #{cap.rake} db:migrate"
        end
      end

      describe 'when files have not changed' do
        before do
          cap.find_and_execute_task 'deploy:migrate'
        end

        it 'should not migrate the database' do
          cap.wont_have_run "cd #{cap.release_path} && #{cap.rake} db:migrate"
        end
      end
    end
  end
end
