require_relative 'helper'
require 'zendesk/deployment/environment_selector'

describe Zendesk::Deployment::EnvironmentSelector do
  before do
    chef_config_location = File.expand_path('hosts.yml', File.dirname(__FILE__))
    discovery = Zendesk::Deployment::EnvironmentDiscovery.new(chef_config_location)

    cap.extend(Zendesk::Deployment::EnvironmentSelector)
    cap.set :application, 'zendesk_deployment'
    cap.set :environment_discovery, discovery
    cap.trigger :load

    $found_hosts = []

    def cap.role_mapping(node)
      $found_hosts << node['host']
      super
    end
  end

  def assert_servers(servers)
    $found_hosts.sort.must_equal servers.sort
    cap.find_servers.map(&:host).sort.must_equal servers.sort
  end

  it 'creates tasks for each of the specified environments' do
    cap.find_task(:master1).wont_be_nil
    cap.find_task(:master2).wont_be_nil
    cap.find_task(:staging1).wont_be_nil
    cap.find_task(:pod1).wont_be_nil
    cap.find_task(:pod2).wont_be_nil
    cap.find_task(:pod3).wont_be_nil
    cap.find_task(:pod4).wont_be_nil
  end

  it 'creates a master task that selects all master environments' do
    cap.find_and_execute_task('master')
    cap.must_have_invoked 'master1'
    cap.must_have_invoked 'master2'
    cap.wont_have_invoked 'staging1'
    cap.wont_have_invoked 'pod1'
    cap.wont_have_invoked 'pod2'
    cap.wont_have_invoked 'pod3'
    cap.wont_have_invoked 'pod4'
  end

  it 'creates a staging task that selects all staging environments' do
    cap.find_and_execute_task('staging')
    cap.wont_have_invoked 'master1'
    cap.wont_have_invoked 'master2'
    cap.must_have_invoked 'staging1'
    cap.wont_have_invoked 'pod1'
    cap.wont_have_invoked 'pod2'
    cap.wont_have_invoked 'pod3'
    cap.wont_have_invoked 'pod4'
  end


  it 'creates a production task that selects all production environments' do
    cap.find_and_execute_task('production')
    cap.wont_have_invoked 'master1'
    cap.wont_have_invoked 'master2'
    cap.wont_have_invoked 'staging1'
    cap.must_have_invoked 'pod1'
    cap.must_have_invoked 'pod2'
    cap.must_have_invoked 'pod3'
    cap.must_have_invoked 'pod4'
  end

  it 'creates gamma tasks from production environments' do
    cap.find_task('pod1:gamma').wont_be_nil
    cap.find_task('pod2:gamma').wont_be_nil
    cap.find_task('pod3:gamma').wont_be_nil
  end

  describe 'master1' do
    let(:master_servers) {
      [ 'master01.rsc.zdsys.com',
        'master02.rsc.zdsys.com',
        'master03.rsc.zdsys.com' ]
    }

    before { cap.find_and_execute_task('master1') }

    it 'selects the master servers' do
      assert_servers master_servers
    end

    it 'sets rails_env to master' do
      cap.rails_env.must_equal 'master'
      cap.default_environment['RAILS_ENV'].must_equal 'master'
    end

    it 'sets production? to false' do
      cap.production?.must_equal false
    end

    it 'sets gamma? to false' do
      cap.gamma?.must_equal false
    end

    it 'sets environment to master' do
      cap.environment.must_equal 'master1'
    end

    it 'executes finalize_environment_selection' do
      cap.must_have_invoked 'finalize_environment_selection'
    end

    describe "#hosts_across_all_projects_with_tag" do
      it 'returns hosts across all projects by a given tag (hc_solr)' do
        expected_servers = ['master14.rsc.zdsys.com']

        cap.hosts_across_all_projects_with_tag('hc_solr').must_equal expected_servers
      end

      it 'does not pollute hosts list' do
        cap.hosts_across_all_projects_with_tag('hc_solr')

        assert_servers master_servers
      end
    end
  end

  describe 'staging' do
    let(:staging_servers) {
      [ 'deploy1.rsc.zdsys.com',
        'staging00.rsc.zdsys.com',
        'staging01.rsc.zdsys.com',
        'staging02.rsc.zdsys.com',
        'staging03.rsc.zdsys.com',
        'staging05.rsc.zdsys.com' ]
    }

    before { cap.find_and_execute_task('staging') }

    it 'selects the staging servers' do
      assert_servers staging_servers
    end
  end

  describe 'staging1' do
    let(:staging_servers) {
      [ 'deploy1.rsc.zdsys.com',
        'staging00.rsc.zdsys.com',
        'staging01.rsc.zdsys.com',
        'staging02.rsc.zdsys.com',
        'staging03.rsc.zdsys.com' ]
    }

    before { cap.find_and_execute_task('staging1') }

    it 'selects the staging servers' do
      assert_servers staging_servers
    end

    it 'sets rails_env to staging' do
      cap.rails_env.must_equal 'staging'
      cap.default_environment['RAILS_ENV'].must_equal 'staging'
    end

    it 'sets production? to false' do
      cap.production?.must_equal false
    end

    it 'sets gamma? to false' do
      cap.gamma?.must_equal false
    end

    it 'sets environment to staging' do
      cap.environment.must_equal 'staging1'
    end

    it 'executes finalize_environment_selection' do
      cap.must_have_invoked 'finalize_environment_selection'
    end

    describe "#hosts_across_all_projects_with_tag" do
      it 'returns hosts across all projects by a given tag (hc_solr)' do
        expected_servers = ['staging02.rsc.zdsys.com']

        cap.hosts_across_all_projects_with_tag('hc_solr').must_equal expected_servers
      end

      it 'does not pollute hosts list' do
        cap.hosts_across_all_projects_with_tag('hc_solr')

        assert_servers staging_servers
      end
    end
  end

  describe 'pod1' do
    let(:pod1_servers) {
      [ 'admin01.ord.zdsys.com',
        'admin04.ord.zdsys.com',
        'admin05.ord.zdsys.com',
        'admin06.ord.zdsys.com',
        'app13.pod1.ord.zdsys.com',
        'app14.pod1.ord.zdsys.com',
        'app15.pod1.ord.zdsys.com',
        'app16.pod1.ord.zdsys.com',
        'proxy06.pod1.ord.zdsys.com',
        'proxy07.pod1.ord.zdsys.com',
        'work06.pod1.ord.zdsys.com',
        'work07.pod1.ord.zdsys.com' ]
    }

    before { cap.find_and_execute_task('pod1') }

    it 'selects the pod1 servers' do
      assert_servers pod1_servers
    end

    it 'sets rails_env to production' do
      cap.rails_env.must_equal 'production'
      cap.default_environment['RAILS_ENV'].must_equal 'production'
    end

    it 'sets production? to true' do
      cap.production?.must_equal true
    end

    it 'sets gamma? to false' do
      cap.gamma?.must_equal false
    end

    it 'sets environment to pod1' do
      cap.environment.must_equal 'pod1'
    end

    it 'executes finalize_environment_selection' do
      cap.must_have_invoked 'finalize_environment_selection'
    end

    describe "#hosts_across_all_projects_with_tag" do
      it 'returns hosts across all projects by a given tag (hc_solr)' do
        expected_servers = [
          'hcsolr01.pod1.ord.zdsys.com',
          'hcsolr02.pod1.ord.zdsys.com',
          'hcsolr03.pod1.ord.zdsys.com'
        ]

        cap.hosts_across_all_projects_with_tag('hc_solr').must_equal expected_servers
      end

      it 'does not pollute hosts list' do
        cap.hosts_across_all_projects_with_tag('hc_solr')

        assert_servers pod1_servers
      end
    end
  end

  describe 'pod1:gamma' do
    let(:gamma_servers) { ['gamma01.pod1.ord.zdsys.com'] }

    before { cap.find_and_execute_task('pod1:gamma') }

    it 'selects the pod1 gamma servers' do
      assert_servers gamma_servers
    end

    it 'sets rails_env to production' do
      cap.rails_env.must_equal 'production'
      cap.default_environment['RAILS_ENV'].must_equal 'production'
    end

    it 'sets production? to true' do
      cap.production?.must_equal true
    end

    it 'sets gamma? to true' do
      cap.gamma?.must_equal true
    end

    it 'sets environment to pod1:gamma' do
      cap.environment.must_equal 'pod1:gamma'
    end

    it 'executes finalize_environment_selection' do
      cap.must_have_invoked 'finalize_environment_selection'
    end

    it 'returns hosts across all projects by a given tag (hc_solr)' do
      cap.hosts_across_all_projects_with_tag('hc_solr').must_equal []
    end

    describe "#hosts_across_all_projects_with_tag" do
      it 'returns hosts across all projects by a given tag (hc_solr)' do
        cap.hosts_across_all_projects_with_tag('hc_solr').must_equal []
      end

      it 'does not pollute hosts list' do
        cap.hosts_across_all_projects_with_tag('hc_solr')

        assert_servers gamma_servers
      end
    end
  end

  describe 'pod2' do
    let(:pod2_servers) {
      [ 'admin1.sac1.zdsys.com',
        'admin2.sac1.zdsys.com',
        'app1.pod2.sac1.zdsys.com',
        'app10.pod2.sac1.zdsys.com',
        'app11.pod2.sac1.zdsys.com',
        'app12.pod2.sac1.zdsys.com',
        'app13.pod2.sac1.zdsys.com',
        'app14.pod2.sac1.zdsys.com',
        'app15.pod2.sac1.zdsys.com',
        'app16.pod2.sac1.zdsys.com',
        'app2.pod2.sac1.zdsys.com',
        'app3.pod2.sac1.zdsys.com',
        'app4.pod2.sac1.zdsys.com',
        'app5.pod2.sac1.zdsys.com',
        'app6.pod2.sac1.zdsys.com',
        'app7.pod2.sac1.zdsys.com',
        'app8.pod2.sac1.zdsys.com',
        'app9.pod2.sac1.zdsys.com',
        'dbadmin1.sac1.zdsys.com',
        'misc1.pod2.sac1.zdsys.com',
        'misc2.pod2.sac1.zdsys.com',
        'misc3.pod2.sac1.zdsys.com',
        'misc4.pod2.sac1.zdsys.com',
        'proxy1.pod2.sac1.zdsys.com',
        'proxy2.pod2.sac1.zdsys.com',
        'proxy3.pod2.sac1.zdsys.com',
        'proxy4.pod2.sac1.zdsys.com',
        'robot1.pod2.sac1.zdsys.com',
        'work1.pod2.sac1.zdsys.com',
        'work2.pod2.sac1.zdsys.com',
        'work3.pod2.sac1.zdsys.com',
        'work4.pod2.sac1.zdsys.com',
        'work5.pod2.sac1.zdsys.com',
        'work6.pod2.sac1.zdsys.com' ]
    }

    before { cap.find_and_execute_task('pod2') }

    it 'selects the pod2 servers' do
      assert_servers pod2_servers
    end

    it 'sets rails_env to production' do
      cap.rails_env.must_equal 'production'
      cap.default_environment['RAILS_ENV'].must_equal 'production'
    end

    it 'sets production? to true' do
      cap.production?.must_equal true
    end

    it 'sets gamma? to false' do
      cap.gamma?.must_equal false
    end

    it 'sets environment to pod2' do
      cap.environment.must_equal 'pod2'
    end

    it 'executes finalize_environment_selection' do
      cap.must_have_invoked 'finalize_environment_selection'
    end

    describe "#hosts_across_all_projects_with_tag" do
      it 'returns hosts across all projects by a given tag (hc_solr)' do
        expected_servers = [
          'hcsolr1.pod2.sac1.zdsys.com',
          'hcsolr2.pod2.sac1.zdsys.com',
          'hcsolr3.pod2.sac1.zdsys.com'
        ]

        cap.hosts_across_all_projects_with_tag('hc_solr').must_equal expected_servers
      end

      it 'does not pollute hosts list' do
        cap.hosts_across_all_projects_with_tag('hc_solr')

        assert_servers pod2_servers
      end
    end
  end
end
