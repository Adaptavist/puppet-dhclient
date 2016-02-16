# Dhclient Module
[![Build Status](https://travis-ci.org/Adaptavist/puppet-dhclient.svg?branch=master)](https://travis-ci.org/Adaptavist/puppet-dhclient)

## Overview

The **Dhclient** module update DNS records for host that use DHCP for network configuration

## Configuration

The following parameters are configurable in Hiera.

* `dnsservers` an array of name server to use in hostname lookups
* `searchdomains` a array of domains to append to unqualified host name when doing a lookup.
* `dhcp_update_key_secret` a secret key for updating via DHCP. Forces use of this module's templates for 'dyn.adaptavist.com.update-key' and the dhclient exit hook.
* `nsupdate_ip_source` where the external IP address, used by the dhclient exit hook, should be sourced. By default this is set to **'$new_ip_address'**
* `disable_network_manager` disabled the NetworkManager if set to true, NetworkManager interferes with the dhclient hooks
* `server_domain` - server domain definition for nsupdate
* `domain` - domain name defined in dhclient.conf
* `name_server` - ns.example.com defines name server param for nsupdate


## Environments that use NAT

In environments that use NAT the default method of identifying the systems external IP address actually ends up setting the internal IP address within DNS.

## Example

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

