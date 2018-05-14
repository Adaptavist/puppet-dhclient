class dhclient(
    $server_domain,
    $name_server,
    $domain,
    $ns_update_hook_path           = '/etc/dhcp/nsupdate.hook.erb',
    $dhcp_update_key_template_path = '/etc/dhcp/domain.update-key.erb',
    $update_key_path               = '/etc/dhcp/domain.update-key',
    $dhcp_update_user              = undef,
    $dhcp_update_key_secret        = undef,
    $dhcp_update_zone_id           = undef,
    $dhcp_update_ttl               = '300',
    $dhcp_update_hook_type         = 'nsupdate',
    $nsupdate_ip_source            = '$new_ip_address',
    $searchdomains                 = [],
    $dnsservers                    = ['8.8.8.8', '8.8.4.4'],
    $disable_network_manager       = true,
    $create_dhclient_exit_hook     = true,
) {
    validate_re($dhcp_update_hook_type, ['^nsupdate$', '^route53$'])
    case $::osfamily {
        'Debian': {
            $network_manager_service = 'network-manager'
            $exit_hook = '/etc/dhcp/dhclient-exit-hooks.d/nsupdate'
            $dhclient_binary = '/sbin/dhclient'
        }
        'RedHat': {
            $network_manager_service = 'NetworkManager'
            $exit_hook = '/etc/dhcp/dhclient-exit-hooks'
            if (versioncmp($::operatingsystemrelease,'7') >= 0 and $::operatingsystem != 'Fedora') {
                $dhclient_binary = '/usr/sbin/dhclient'
            } else {
                $dhclient_binary = '/sbin/dhclient'
            }
            package { 'bind-utils': ensure => 'installed' }
        }
        default: {
            fail("Unsupported operating system family: ${::osfamily}")
        }
    }

    # create dhclient config, this includes domain, search domain and dns servers
    file { '/etc/dhcp/dhclient.conf':
            content => template("${module_name}/dhclient.conf.erb"),
            notify  => Exec['restart dhclient']
    }

    # if required create dhclient exit hook and nsupdate key
    if str2bool($create_dhclient_exit_hook) {
        # if we are creating nsupdate exit hook create the udate key and set the requirements for service restart
        if ( $dhcp_update_hook_type == 'nsupdate' ) {
            if ($dhcp_update_key_secret) {
                $update_key_template_path  = "${module_name}/domain.update-key.erb"
                $update_hook_path = "${module_name}/nsupdate_exithook.erb"
            } else {
                $update_key_template_path  = $dhcp_update_key_template_path
                $update_hook_path = $ns_update_hook_path
            }

            file { $update_key_path:
                content => template($update_key_template_path);
            }

            if ($::osfamily == 'Debian') {
                $restart_require = [File['/etc/dhcp/dhclient.conf'],File[$update_key_path],File[$exit_hook]]
            } elsif ($::osfamily == 'RedHat') {
                $restart_require = [File['/etc/dhcp/dhclient.conf'],File[$update_key_path],File[$exit_hook],Package['bind-utils']]
            }
        # if however we are creating a route53 exit hook just set the requirements for service restart
        } elsif ( $dhcp_update_hook_type == 'route53' ) {
            $update_hook_path = "${module_name}/route53_exithook.erb"
            if ($::osfamily == 'Debian') {
                $restart_require = [File['/etc/dhcp/dhclient.conf'],File[$exit_hook]]
            } elsif ($::osfamily == 'RedHat') {
                $restart_require = [File['/etc/dhcp/dhclient.conf'],File[$exit_hook],Package['bind-utils']]
            }
        }

        # generate the actual exit hook
        file { $exit_hook:
                content => template($update_hook_path),
                mode    => '0755',
                notify  => Exec['restart dhclient']
        }

    } else {
        $restart_require = [File['/etc/dhcp/dhclient.conf']]
    }

    # NetworkManager interferes with dhclient hooks, disable it if instructed to do so
    # This is currently limited to RedHat based systems as the Debian/Ubuntu provider erros if it tries to disable a non-existing service
    if (str2bool($disable_network_manager) and $::osfamily == 'RedHat') {
        service { $network_manager_service:
            ensure => 'stopped',
            enable => false,
            before => Exec['restart dhclient']
        }

        # ensure this change is made before packages are installed
        Service[$network_manager_service] -> Package<| |>
    }
    # Use pkill not dhclient -x to ensure IP lease isnt lost
    exec { 'restart dhclient':
        command     => "/usr/bin/pkill dhclient; ${dhclient_binary}",
        require     => $restart_require,
        refreshonly => true,

    }
}
