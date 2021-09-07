---
title: Static Routing
parent: Network Configuration
---

# IPv4 Static Routing

## Introduction

As a L3-enabled SDN controller, baseboxd can be configured for routing purposes. Examples in this part are added to show how IP addresses (IPv4 and IPv6) and routes can be attached to certain interfaces. Managing static routes is done typically via iproute2 and systemd-networkd, and the following sections will describe this in more detail. For dynamic routing, BISDN adopted FRRouting, to support routing protocols such as BGP and OSPF.

**WARNING**: Configuring a Linux box to work as a router assumes that sysctl net.ipv4.conf.all.forwarding=1. BISDN Linux has this sysctl already enabled by default, but routing issues should be debugged first by checking the value for this configuration.
{: .label .label-red }

## iproute2

Adding an IP address to a baseboxd interface is done simply by

```
ip link set ${PORT} up
ip address add ${IPADDRESS} dev ${PORT}
```

Configuring a static route on the interface via ip route:

```
ip route add ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}
```

Route and IP address deletion is done via

```
ip address del ${IPADDRESS} dev ${PORT}
ip route del ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}
```

## systemd-networkd

IPv4 routing in systemd-networkd is done using the [Network] and [Route] sections to the port .network file. In the [Route] section, the Gateway= section *must* be present in the case when DHCP is not used.

```
10-port1.network:

[Match]
Name=${PORT}

[Network]
Address=${IPADDRESS}

[Route]
Gateway=${GATEWAY}
Destination=${DESTINATION_NETWORK}/${DESTINATION_MASK}
```

# IPv6 Static Routing

## Introduction

IPv6 is supported in BISDN Linux and baseboxd. It provides simpler network provisioning mechanism, due to address auto-configuration and the advantage of building more recent and stable networks.

IPv6 addresses are composed of 128 bits, separated by eight groups of four hexadecimal digits, for example:

```
FE80:0000:0000:0000:0202:B3FF:FE1E:8329 : long version
FE80::202:B3FF:FE1E:8329 : short version
```

Prefixes for IPv6 addresses can then be represented similarly to network masks in IPv4, with the notation <ip adddress>/<prefix>, where this prefix is an integer between 1-128. Despite having the possibility of configuring prefixes with this entire range, many of the IPv6 advantages brings, like address auto-configuration works solely with the /64 prefix.

There are some specific reserved network addresses, like the fe80::/10 address family. This block is reserved to be used in Link-Local Unicast addresses, and, in combination with the MAC address of an interface is used to generate a non-routable address used to exchange Router and Neighbor Advertisements, for example.

Similarly to IPv4, there are also some Linux sysctls present to control IPv6 behavior. The forwarding sysctl, net.ipv6.conf.all.forwarding, is in BISDN Linux as well 1, allowing for the switch to forward IPv6 packets. This affects as well the net.ipv6.conf.<interface>.accept_ra sysctl, since routers are not designed to accept Router Advertisements, and using them to configure the IPv6 address. Router advertisements (RA) are the periodically transmitted messages upon reception of Router Solicitations sent by hosts. The host then used the information present in these RA messages, like the prefixes and network parameters to auto-configure the addresses on the links and default gateway.

## iproute2

Configuring IPv6 addresses in BISDN Linux, using iproute2 is done via the following commands

```
ip link set ${PORT} up
ip address add ${IPADDRESS} dev ${PORT}
```

Configuring the router to transmit RA messages is possible in several ways. One of the supported ways to transmit these messages is via the Router Advertisement Deamon (radvd). The configuration file for this daemon is present on /etc/radvd.conf.

```
/etc/radvd.conf:

interface ${PORT}
{
        AdvSendAdvert on;
        MinRtrAdvInterval 30;
        MaxRtrAdvInterval 100;
        prefix 2003:db8:1:0::/64
        {
                AdvOnLink on;
                AdvAutonomous on;
                AdvRouterAddr off;
        };
};
```

This configuration example selects the interface where to send the advertisements on, and the prefix it should announce. The interval between each message can also be fine tuned. Further documentation on this tool can be found in [here](https://linux.die.net/man/5/radvd.conf).

Adding a static IPv6 route is done via

```
ip route add ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}
```

So, addition and deletion of IP addresses and routes follow the same workflow as in the IPv4 case. In order to check the configured IPv6 routes, the following command must be run

```
ip -6 route list
```

Adding the -4/6 argument to the call allows to show only the desired routes/ addresses by IP protocol.

For ‘systemd-networkd’ the configuration file is done the same way.

## Static route example

Here we will give a simple example of using static routes on four nodes. Two
switches and two server, as shown on the figure below.

#
#  +-------------------------------------------+   +-------------------------------------------+
#  | switch-1                                  |   | switch-2                                  |
#  |                                           |   |                                           |
#  |     10.0.1.1/24            10.0.3.1/24    |   |     10.0.3.2/24            10.0.2.1/24    |
#  |+------------------+   +------------------+|   |+------------------+   +------------------+|
#  ||      port2       |   |      port54      ||   ||     port54       |   |    port2         ||
#  ++------------------+---+------------------++   ++------------------+---+------------------++
#            |                       |                       |                     |
#            |                       |                       |                     |
#            |                       +-----------------------+                     |
#            |                                                                     |
#            |                                                                     |
#            |                                                                     |
#  ++-----------------------------+                             +----------+-------+----------++
#  ||      eno2        |          |                             |          |      eno2        ||
#  |+------------------+          |                             |          +------------------+|
#  |       10.0.1.2/24            |                             |                 10.0.2.2/24  |
#  |                              |                             |                              |
#  | server1                      |                             | server2                      |
#  +------------------------------+                             +------------------------------+
#

# Setup switch-1

This sets ``port2`` up and adds the ip address 10.0.1.1/24.

`switch-1 /etc/systemd/network/30-port_left.network`
```
Match:
  Name: port_left
Network:
  Address: 10.0.1.1/24
```

This sets ``port54`` up, adds ip address 10.0.3.1 and adds a route to the
10.0.2.0/24 subnet (which is on ``server-2``) via 10.0.3.2

`switch-1 /etc/systemd/network/30-port_switch.network`
```
Match:
  Name: port_switch
Network:
  Address: 10.0.3.1/24
Route:
  Destination: 10.0.2.0/24
  Gateway: 10.0.3.2
```

# Setup switch-2

Set ``port2`` up and add ip address 10.0.2.1/24.

`switch-2 /etc/systemd/network/30-port_left.network`
```
Match:
  Name: port_left
Network:
  Address: 10.0.2.1/24
```

This sets ``port54`` up, adds ip address 10.0.3.2 and adds a route to the
10.0.1.0/24 subnet (which is on ``sever-1``) via 10.0.3.1

`switch-2 /etc/systemd/network/30-port_switch.network`
```
Match:
  Name: port_switch
Network:
  Address: 10.0.3.2/24
Route:
  Destination: 10.0.1.0/24
  Gateway: 10.0.3.1
```

# Setup server-1

This adds ip address 10.0.1.2/24 to ``eno2`` and a route to the subnet
10.0.2.0/24 (which is on ``server-2``) via 10.0.1.1

`server-1 /etc/systemd/network/30-eno2.network`
```
Match:
  Name: eno2
Network:
  Address: 10.0.1.2/24
Route:
  Destination: 10.0.2.0/24
  Gateway: 10.0.1.1
```

# Setup server-2

This adds ip address 10.0.2.2/24 to ``eno2`` and a route to the subnet
10.0.1.0/24 (which is on ``server-1``) via 10.0.2.1

`server-2 /etc/systemd/network/30-eno2.network`
```
Match:
  Name: eno2
Network:
  Address: 10.0.2.2/24
Route:
  Destination: 10.0.1.0/24
  Gateway: 10.0.2.1
```

Restart systemd-networkd or reboot the switches to apply network configuration.
