require 'spec_helper'

dhcp_update_key_template_path = "/etc/dhcp/domain.update-key"
ns_update_hook_path = "/etc/dhcp/nsupdate.hook"
exit_hook_redhat = '/etc/dhcp/dhclient-exit-hooks'
exit_hook_debian = '/etc/dhcp/dhclient-exit-hooks.d/nsupdate'
debian_service = 'network-manager'
redhat_service = 'NetworkManager'
server_domain = 'example.com'
name_server = 'ns.example.com'
secret = 'secret'
domain = 'example.com'
nsupdate_ip_source = '$new_ip_address'
dhclient_binary_redhat = '/usr/sbin/dhclient'
dhclient_binary = '/sbin/dhclient'
default_dhcp_update_hook_type = 'nsupdate'
route53_user = 'user1'
route563_key = 'abcdefghijk1234567'
route53_zoneid = 'Z5173462'
ttl = 600


describe 'dhclient', :type => 'class' do

  context "Should disable network manager on redhat and setup dhconfig, nsupdate" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7', 
      }}
    let(:params) {{
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :dhcp_update_hook_type => default_dhcp_update_hook_type
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should contain_file(exit_hook_redhat)
        .with_content(/nsupdate -k \/etc\/dhcp\/domain.update-key <<EOF 2>\/tmp\/hook.error/)
        .with_content(/server #{name_server}/)
        .with_content(/zone #{server_domain}/)
        .with_content(/show/)
        .with_content(/send/)
      should contain_file(dhcp_update_key_template_path)
        .with_content(/secret "#{secret}";/)
        .with_content(/algorithm HMAC-SHA512;/)
        .with_content(/key #{server_domain}. {/)
      should contain_service(redhat_service).with(
        'ensure' => 'stopped',
        'enable' => 'false',
        )
      should contain_exec('restart dhclient').with(
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary_redhat}",
        )
    end
  end

  context "Should setup route53 exit hook instead of nsupdate" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7', 
      }}
    let(:params) {{
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :dhcp_update_hook_type => 'route53',
      :dhcp_update_user => route53_user,
      :dhcp_update_key_secret => route563_key,
      :dhcp_update_zone_id => route53_zoneid,
      :dhcp_update_ttl => ttl,
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should contain_file(exit_hook_redhat)
        .with_content(/Domain="#{domain}"/)
        .with_content(/ZoneID="#{route53_zoneid}"/)
        .with_content(/AmazonID="#{route53_user}"/)
        .with_content(/SecretKey="#{route563_key}"/)
        .with_content(/NewTTL=#{ttl}/)
        .with_content(/CurrentIP=\$new_ip_address/)
      should_not contain_file(dhcp_update_key_template_path)

      should contain_exec('restart dhclient').with(
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary_redhat}",
        )
    end
  end

  context "Should disable network manager on redhat < 7 and setup dhconfig, nsupdate with searchdomains" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '6.0'
      }}
    let(:params) {{
      :searchdomains => ['searchdomain1.com', 'searchdomain2.com'],
      :dnsservers    => ['8.8.8.8'],
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :dhcp_update_hook_type => default_dhcp_update_hook_type
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8;/)
        .with_content(/supersede domain-search "searchdomain1.com", "searchdomain2.com";/)
      
      should contain_file(exit_hook_redhat)
        .with_content(/nsupdate -k \/etc\/dhcp\/domain.update-key <<EOF 2>\/tmp\/hook.error/)
        .with_content(/server #{name_server}/)
        .with_content(/zone #{server_domain}/)
        .with_content(/show/)
        .with_content(/send/)
      should contain_file(dhcp_update_key_template_path)
        .with_content(/secret "#{secret}";/)
        .with_content(/algorithm HMAC-SHA512;/)
        .with_content(/key #{server_domain}. {/)
      should contain_service(redhat_service).with(
        'enable' => 'false',
        )
      should contain_exec('restart dhclient').with(
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary}",
        )
    end
  end

  context "Should disable network manager on debian and setup dhconfig, nsupdate" do
    let(:facts){{
      :osfamily => 'Debian',
      }}
    let(:params) {{
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :dhcp_update_hook_type => default_dhcp_update_hook_type
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should contain_file(exit_hook_debian)
        .with_content(/nsupdate -k \/etc\/dhcp\/domain.update-key <<EOF 2>\/tmp\/hook.error/)
        .with_content(/server #{name_server}/)
        .with_content(/zone #{server_domain}/)
        .with_content(/show/)
        .with_content(/send/)
      should contain_file(dhcp_update_key_template_path)
        .with_content(/secret "#{secret}";/)
        .with_content(/algorithm HMAC-SHA512;/)
        .with_content(/key #{server_domain}. {/)
      should_not contain_service(debian_service)

      should contain_exec('restart dhclient').with(
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary}",
        )
    end
  end

  context "Should disable network manager on debian and setup dhconfig but not nsupdate key or hook" do
    let(:facts){{
      :osfamily => 'Debian',
      }}
    let(:params) {{
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :create_dhclient_exit_hook => false,
      :dhcp_update_hook_type => default_dhcp_update_hook_type
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should_not contain_file(exit_hook_debian)
      should_not contain_file(dhcp_update_key_template_path)
      should_not contain_service(debian_service)

      should contain_exec('restart dhclient').with(
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary}",
        )
    end
  end

  context "Should error when an unsupported update hook type is specified" do
    let(:facts){{
      :osfamily => 'Debian',
      }}
    let(:params) {{
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      :create_dhclient_exit_hook => false,
      :dhcp_update_hook_type => 'faketype'
      }}
    it do
      should raise_error(Puppet::Error, /"faketype" does not match/)
    end
  end

end
