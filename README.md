# Dhclient Module
[![Build Status](https://travis-ci.org/Adaptavist/puppet-dhclient.svg?branch=master)](https://travis-ci.org/Adaptavist/puppet-dhclient)

## Overview

The **Dhclient** module update DNS records for host that use DHCP for network configuration, it currenty supports the creation of an dhclient exit hook to update DNS via either nsupdate or a custom script to update Amazon Route 53

## Configuration

The following parameters are configurable in Hiera.

* `dnsservers` an array of name server to use in hostname lookups
* `searchdomains` a array of domains to append to unqualified host name when doing a lookup.
* `dhcp_update_hook_type ` determines what type of hook to create, currently only 'nsupdate' and 'route53' are supported.  By default this is set to **'nsupdate'**
* `dhcp_update_key_secret` a secret key for updating via DHCP. Forces use of this module's templates for 'dyn.adaptavist.com.update-key' and the dhclient exit hook.  This is only needed if using the 'nsupdate' hook type
* `dhcp_update_user` the user to use to perform the DNS update.  This is only needed if using the 'route53' hook type
* `dhcp_update_zone_id` the DNS zone id to update.  This is only needed if using the 'route53' hook type
* `dhcp_update_ttl`  the Time To Live for the new DNS entry. By default this is set to **'300'**
* `nsupdate_ip_source` where the external IP address, used by the dhclient exit hook, should be sourced. By default this is set to **'$new_ip_address'**
* `disable_network_manager` disabled the NetworkManager if set to true, NetworkManager interferes with the dhclient hooks
* `server_domain` - server domain definition for nsupdate
* `domain` - domain name defined in dhclient.conf
* `name_server` - ns.example.com defines name server param for nsupdate


## Environments that use NAT

In environments that use NAT the default method of identifying the systems external IP address actually ends up setting the internal IP address within DNS as the $new_ip_address variable contains the internal not external IP address.  In this situation it is advisable to change the "nsupdate_ip_source" param to get the IP from another source (AWS meta-data API or external web site...), an example would be $(curl ifconfig.co), and would be set like this via hiera `dhclient::nsupdate_ip_source: '$(curl ifconfig.co)'`

## Examples

```
dhclient::domain: 'example.com'
dhclient::server_domain: 'an.example.com'
dhclient::name_server: 'ns.example.com'
dhclient::dhcp_update_key_secret: "some secret key, preferrably encrypted using eyaml"
dhclient::nsupdate_ip_source: '$new_ip_address'
dhclient::dnsservers:
  - 8.8.8.8
dhclient::searchdomains:
  - example.com
  - another.example.com
```

## Dependencies

This module has no dependencies on other puppet modules.

