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
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should contain_file(exit_hook_redhat)
        .with_content(/nsupdate -k \/etc\/dhcp\/#{server_domain}.update-key <<EOF 2>\/tmp\/hook.error/)
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
        'command' => "/usr/bin/pkill dhclient; #{dhclient_binary_redhat}",
        )
    end
  end

  context "Should disable network manager on redhat < 7 and setup dhconfig, nsupdate with searchdomains" do
    let(:facts){{
      :osfamily => 'RedHat',
      }}
    let(:params) {{
      :searchdomains => ['searchdomain1.com', 'searchdomain2.com'],
      :dnsservers    => ['8.8.8.8'],
      :server_domain => server_domain,
      :name_server => name_server,
      :dhcp_update_key_secret => secret,
      :domain => domain,
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8;/)
        .with_content(/supersede domain-search "searchdomain1.com", "searchdomain2.com";/)
      
      should contain_file(exit_hook_redhat)
        .with_content(/nsupdate -k \/etc\/dhcp\/#{server_domain}.update-key <<EOF 2>\/tmp\/hook.error/)
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
      }}
    it do
      should contain_file('/etc/dhcp/dhclient.conf')
        .with_content(/supersede domain-name "#{domain}";/)
        .with_content(/supersede domain-name-servers 8.8.8.8, 8.8.4.4;/)
      
      should contain_file(exit_hook_debian)
        .with_content(/nsupdate -k \/etc\/dhcp\/#{server_domain}.update-key <<EOF 2>\/tmp\/hook.error/)
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

end
