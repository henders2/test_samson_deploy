# Zendesk Deployment [![Build Status](https://next.travis-ci.com/zendesk/zendesk_deployment.png?token=rTSBK3dcN92aXMyXCTyv&branch=master)](https://next.travis-ci.com/zendesk/zendesk_deployment)


**Note: this documentation is the pre-release 2.0 version of zendesk_deployment.**

**Use the [v1-14-stable](https://github.com/zendesk/zendesk_deployment/tree/v1-14-stable) branch to view the 1.0 version documentation.**

To use these capistrano extensions you need a Capfile that looks something like this:

```ruby
require 'zendesk/deployment'

set :application, 'awesome_app'
set :repository,  'git@github.com:zendesk/awesome_app.git'
```

That is the minumum. __DO NOT REQUIRE capistrano/deploy IN YOUR Capfile__.

After that you can deploy your application like this:
`bundle exec cap pod1 deploy TAG=v1.2`

## Optional

```ruby
# a list of people to notify about deploys
set :email_notification, ['deploys@zendesk.com', 'mick@zendesk.com']

# specify a ruby version to use on the servers during deploys
set :ruby_version, 'ree'

# specify multiple ruby versions to bundle during deploys
# set :ruby_versions, ['ree, '2.1.4']
```

For testing or emergencies, you can also use an alternative hosts.yml for
environment discovery via the `ZENDESK_HOSTS_FILE` env var. eg. `bundle exec cap pod1 deploy TAG=v1.2 ZENDESK_HOSTS_FILE=/path/to/your/hosts.yml`

## Strategy

#### Features

* Discovery of what servers to deploy to by looking at the chef config files.
* Runs `bundle install` during deploys.
* Unique deploy directory per release.
* Uses rbenv on the servers to run the right ruby version (based .ruby_version).
* Protects against drunk people deploying to production. (only through interacive terminals)
* Uploads a deploy log to the servers.
* Protects against deploy collisions with a lock file.
* Requires you to specify a tag when deploying to production.
* Email notifications.

#### Steps

###### deploy:build

1. Build a tarball of the release revision
  * Using `git archive`, all the code in repository
  * If there is a Gemfile, this includes a complete `bundle package --all`
  * Can be hooked into by `deploy:prepare_project` to add compilation and extra paths
2. Upload it to all mirrors via FTP
  * For security, this strategy can only be used inside our datacenters or Amazon VPC (ie. not Rackspace Cloud).

###### deploy:release

1. Verify the integrity of the release tarball
1. Download the tarball to release hosts
2. Extract the release to a unique directory
2. If there is a Gemfile, `bundle --deployment` (very quick with the bundle package)
3. Switch symlink, restart


To run both `deploy:build` and `deploy:release` in one step, use `deploy`.


## Forcing a clean installation of gem dependencies

Sometimes you might need to reinstall all gems.

You can trigger a rebundle with the `force_rebundle` environment varialbe: `force_rebundle=true cap pod1 deploy`.
A rebundle will also be triggered if the `/etc/rebundle` file is present on the server.
The presence of a project specific `/etc/rebundle-#{deploy_project_name}` will also trigger a rebundle.

## Bundler

If your project has a Gemfile, Zendesk Deployment will make sure to bundle on the specified ruby version(s) during deployment.
You can specify which version of bundler you want to use by setting the `bundler_version` variable.
