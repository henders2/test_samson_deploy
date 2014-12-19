### v2.0.0.rc2

* add a new mirror strategy
  * this is essentially build + release
  * more info @ https://github.com/zendesk/zendesk_deployment#strategy
* completely remove all other strategies, mirror strategy is now the default
* deploy:update_code became deploy:fetch_archive_from_mirror

### v1.14.3

* mirrored\_releases: don't clean up alpha/omega
* mirrored\_releases: add workaround for single AWS mirror

### v1.14.1

* changes the host regexp from /^gamma/ to /gamma/

### v1.14.0

* uses the repository differences to check if db:migrate needs to be run
* adds run_locally to Util module

### v1.13.2
* mirrored\_releases: update mirror discovery to work with different
  environments

### v1.13.1

### v1.13.0
* migrations now run on each primary DB role

### v1.12.7
* mirrored\_releases: fix bug in referring to environment in wrong context

### v1.12.6
* mirrored\_releases: update 'deploy:switch' logic
* mirrored\_releases: add 'deploy:switch_live' task for interactive switch

### v1.12.5
* mirrored\_releases: make mirrors autodiscoverable

### v1.12.4
* bundler: allow the `bundle_command` to be overridden
* mirrored\_releases: override the `bundle_command` to always bundle when
  using `bundle package --all`
* mirrored\_releases: change fetch retry defaults

### v1.12.3
* mirrored\_releases: Fix incorrect mirror hostname in docs
* mirrored\_releases: Fix bundle config

### v1.12.2
* no more default for ruby_version, set it yourself and add it to your cookbook

### 1.12.1

* mirrored\_releases: Add bundle package --all as an option (enabled by default)
* mirrored\_releases: Need to set deploy\_mirror role in Capfiles until env
  discovery is updated.

### 1.12.0

* Add new mirrored\_releases (tarball+mirror) deploy strategy
* Fail gracefully if `/etc/zendesk/hosts.yml` is not present
* Don't run check\_setup, lock, log upload tasks on no\_release hosts

### 1.11.0 __SKIP__

* This release was reverted

### 1.10.17
* Added RunRetry feature which provides a run_with_retry() wrapper around the
  standard run() command.  It will attempt the command three times by default
  but is also configurable.
* DualGitReleases :update_code takes advantage of run_with_retry() to improve
  the chances of success when talking to GitHub

### 1.10.16
* Allow check_services to fail with `set :allow_check_services_failure, true`

### 1.10.15
* Don't abort the discovery of servers for a pod environment as it
  fails for high level environments such as staging.

### 1.10.14
* don't warn/abort for local deploy if the ssh gateway is an aws host

### 1.10.13
* add option to set an ssh gateway via the environment variable
  `CAP_SSH_GATEWAY`. Needed to deploy to aws pods from production samson

### 1.10.12
* Revert "Doesn't run :check_setup and :upload_log if host is :no_release"
* BUGFIX: there was an issue where we were trying to upload the deploy_log_summary
  to all hosts, even the one we haven't talk to.

### 1.10.11 __DO NOT USE THIS VERSION__
* Doesn't run :check_setup and :upload_log if host is :no_release
  Needed by Help Center. We don't deploy our code on solr host but
  we deploy schemas on those with a Capistrano task


### 1.10.10

* Add #hosts_across_all_projects_with_tag(path)
  This will return all hosts matching a give tag across all projects
  but on the current pod and environment. Reintroduced after removing it
  in 1.10.9 with more spec.

### 1.10.9

* revert #hosts_across_all_projects_with_tag(path) it's buggy
  it pollutes the hosts list after it's called

### 1.10.8 __DO NOT USE THIS VERSION__

* Add #hosts_across_all_projects_with_tag(path)
  This will return all hosts matching a give tag across all projects
  but on the current pod and environment.
* Add #changes_in?(*files)
  This accepts a list of file paths and will return true if there has been a
  change (git wise) in those. False otherwise.

### 1.10.5

* Fix broken log symlinks.

### 1.10.4

* Fix bugs in shared strategy relating to the use of special characters in
  branch names -- release\_name always uses short revision now.

### 1.10.3

* Add /data/samson/config to search space for NewRelic license key

### 1.10.2

* Fixed a bad bug in production environment selection, where
  pod1 would always be selected.

### 1.10.1 __DO NOT USE THIS VERSION__

* Don't blow up on custom hosts.yml files.

### 1.10.0 __DO NOT USE THIS VERSION__

* You can now specify which version of bundler to use.
* We are now better at discovering non-production environments.

### 1.9.4

* Only display found servers once
* Fix interactivity logic

### 1.9.3

* Only challenge the deployer if the session is interactive.

### 1.9.2

* A little less noise during bundling.

### 1.9.1

* Just some more logging during bundling.
* No longer ask for confirmation if you are non-interactive

### 1.9.0

* Introduce a master and production task to deploy to multiple environments.
* Speed up bundle cleanup.

### 1.8.1

* Delete a potential old bundle before symlinking in the new one.

### 1.8.0

* You can no longer deploy from you local box.
* New pods are now automatically discovered from /etc/zendesk/hosts.yml.
* Introduce the shared git releases (experimental).

### 1.7.3

* Fix bug with verify\_local\_git\_status vs real\_revision when using
  annotated tags
* A brand new bundling strategy.

### 1.7.2

* Reverted the change in 1.7.1.

### 1.7.1

* We now default to using a bundle path shared between releases.

### 1.7.0

* You can disable confirmation on deploy:switch by setting
  `confirm_deploy_switch?` to `false`

### 1.6.0

* You can now specify the `bundle_path`, which defaults to `vendor/bundle`.
* We now ensure to create a shared directory.
* `deploy:setup` now always runs before `deploy:update_code`.
* By default, we now always run migrations in non-production environments.
  Migration for production environments can be controlled with check_for_pending_migrations?

### 1.5.0

* You can now force a rebundle of gem dependencies.
* Switched out the rvm module for a rbenv based ruby_version module.

### 1.4.0

* Added newrelic configuration module.

### 1.3.2

* allow for custom host selection, for projects that go outside the normal deploy process

### 1.3.1

* `deploy:update_git_source` now has a lock around it.

### 1.3.0

* `deploy:update_git_source` will update the git origin in case you change the repository.
* Added a `finalize_environment_selection` hook for when the server environment has been configured.
* Added support for our new git mirrors.

### 1.2.8

* Set RAILS_ENV

### 1.2.7

* Fix log uploading (don't attempt to upload to localhost).

### 1.2.6

* Add pod3.

### 1.2.5

* Only upload logs to the servers we connected to.

### 1.2.4

* Log uploading is now done at exit.
* Use the presence of `/etc/zendesk/hosts.yml` to determine if we are on an admin host.

### 1.2.2

* We now verify restart with the `check_services` script.

### 1.2.1

* Restarts are now done by root.

### 1.2.0

* There is now a default implementation of deploy:restart that should work for most projects.

### 1.1.0

* Deploy logs are now stored in their own directory.

### 1.0.1
* Fix a bug where master1 and master2 would have a generated gamma task.

### 1.0.0
* __BREAKING CHANGE__: use the new /etc/zendesk/hosts.yml for environment discovery.
  * There is no longer an environemnt called master. It has been replaced by master1 and master2.
  * role_mapping is now given a different node object. In most cases you can just delete your role_mapping method.
  * __Chef needs to know about your application before you can switch to 1.0.0.__

### 0.16.0
* Enforces the `local_deploy_is_safe` option.

### 0.15.0
* Check that all deploy hosts are in a deployable state before trying to lock.

### 0.14.0

* The bundle install step is now a real task called `bundle`.
* Improved host selection.

### 0.13.0

* EnvironmentSelector now provides a better deploy_host variable.
* EnvironmentSelector now provides a on_deploy_host? variable.
* deploy:update_code now clones the repo if it is not present.
* The check for pending migrations now aborts if the rake task fails.

### 0.12.0

* Added the bundle:list to show which gems are used.
* Improved colors on questions and errors.
* We now log the list of servers in the environment.

### 0.11.0

* Slightly modified server selection to better match what alpha_omega did.

### 0.10.1

* Ask for confirmation if you are not currently at the SHA you are deploying.

### 0.10.0

* You can now disable individual modules with the `disable_deploy_features` variable.

### 0.9.1

* Fixed deployments from admin hosts.

### 0.9.0

* Abort if you are not locally at the same tag as what you are deploying.
* Ask for confirmation if you are deploying from a dirty repository.
* Ask for confirmation if you are deploying from your local box.
* Improved log file names for natural ordering.

### 0.8.1

* deploy:show_hosts now also outputs information about the server roles and options.
* Added DB environments.

### 0.8.0

* Better abort messages.
* deploy:setup is now idempotent
* Making it easier to override deploy:update_code by moving finalize_update to a callback
* Added the deploy:show_hosts to list the hosts in the environment

### 0.7.0

* Added an airbrake module.
* Fix the SHAs outputted by the tags task.
* Set the :scm variable as some thirdparty recipied depend on it.

### 0.6.0

* Improved output when bundling on multiple rubies.
* More configurable migration module.
* We no ask if you want to run migrations if there are pending migrations.

### 0.5.0

* Changing the log level no longer affects full_log.

### 0.4.0

* Better email notification.
* Default deployment ref is current local HEAD.
* Support of deployment from local and admin box.
* Suppprt for deployments to gamma servers.
* Optional database migrations module.
