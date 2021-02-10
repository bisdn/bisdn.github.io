---
title: Virtual Router Redundancy Protocol (VRRP)
parent: Network Configuration
---

# Virtual Router Redundancy Protocol

## Introduction

The Virtual Router Redundancy Protocol (VRRP) allows the management and
assignment of "virtual" IP addresses to hosts that share at least one common
network and operate with the same virtual routed ID. On BISDN Linux this feature
is provided by [keepalived](https://github.com/acassen/keepalived) and
comprehensive documentation on all the available configuration options within
keepalived can be found in the official
[docs](https://keepalived.readthedocs.io/en/latest/configuration_synopsis.html).

## VRRP configuration overview

The keepalived configuration file can be found in the /etc/keepalived/
directory. The /etc/keepalived/samples/ subdirectory contains a lot of examples
on how different scenarios can be configured, but please be aware that your
switch platform may not be able to run all of these scenarios out-of-the-box
since not all of the needed software is installed or even available. To get
started with keepalived, the following section provides a simple scenario in
which a IPv4 address is shared between two switches/routers. This example could
be used as base to configure a redundant router as gateway on spine switches in
a typical leaf-spine network architecture.

## VRRP IPv4 - shared virtual IP example

To get started, please open the /etc/keepalived/keepalived.conf file and replace
the example content in it with a configuration similar to this:

```
vrrp_instance VIP_1 {
    state MASTER
    interface {{ interface }}
    priority {{ priority }}
    virtual_router_id {{ virtual_router_id }}
    authentication {
        auth_type PASS
        auth_pass password
    }
    virtual_ipaddress {
        {{ virtual_ip }}
    }
}
```

In this example keepalived.conf, you need to replace `{{ interface }}` with the
name of the interface on which the `{{ virtual_ip }}` should be configured. To
define which of the switches/routers should have the `{{ virtual_ip }}` by
default, you need to set a router specific `{{ priority }}` on each router,
where the one with the highest priority will get the IP as long as it is
available. To be able to use multiple instance of VRRP within a layer-2 domain,
you should also make sure to set a unique `{{ virtual_router_id }}` for each
vrrp_instance.  Finally you need to replace `{{ virtual_ip }}` with the IPv4
address that you want to use as the shared virtual IP on the `{{ interface }}`
configured earlier. 
Although the above mentioned configuration already is a fully function
keepalived.conf, it is not sufficient for running VRRP between multiple routers.
In addition to the configuration for VRRP in keepalived.conf, you need to make
sure that all routers are able to communicate with each other and exchange VRRP
announcements. To do this, you can simply pick a unique IPv4 address out of the
same network your shared virtual IPv4 address is out of for each of the routers
and assign it to the same interface you used for `{{ interface }}`. 
An example setup could assign the following IPv4 addresses:

```
router-1:
  port54: 10.0.0.2/24

router-2:
  port54: 10.0.0.3/24
```

As shared virtual IPv4 address you could use 10.0.0.1/32 (please be aware to NOT
specifically set the /32 netmask in the keepalived.conf since this will be added
automatically).

To find out more about how to configure IPv4 addresses in BISDN Linux, please
refer to the section in [getting started](https://docs.bisdn.de/getting_started/basic_networking.html#persisting-network-configuration-with-systemd-networkd).
We recommend to not use frr zebra in combination with keepalived, since both
service are not configured to wait for each other during startup, which might
lead to race conditions in the configuration of interfaces (making those service
depend on each other sounds like an easy solution here, but since their purpose
is very different in each configuration and frr has it's very own internal
service startup management, we think those two should stay independent).

To start your new configuration, just run `systemctl start keepalived` and if
you want to enable VRRP even after reboot, you should run `systemctl enable
keealived`.
