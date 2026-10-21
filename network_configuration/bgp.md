---
title: Border Gateway Protocol (BGP)
parent: Network Configuration
---

# Border Gateway Protocol

## Introduction

The Border Gateway Protocol (BGP) is a distance-vector routing protocol. It was
originally designed to support IPv4 networks in
[RFC4721](https://tools.ietf.org/html/rfc4271.html), and later extended to
support other protocols, such as IPv6, in
[RFC2858](https://tools.ietf.org/html/rfc2858.html). Contrary to OSPF, where
its IPv4 and IPv6 are defined in FRR with different daemons/files, the FRR BGP
daemon can be configured for both protocols. Its complete documentation for FRR
can be found [here](http://docs.frrouting.org/en/latest/bgp.html).

In this section, we provide examples on how to configure BGP for both
[IPv4](#bgp-for-ipv4-networks) and [IPv6](#bgp-for-ipv6-networks) or
[Unnumbered BGP](#unnumbered-bgp) networks in BISDN Linux.

## BGP configuration overview

The FRR configuration files can be found in the /etc/frr/ directory. Each
routing protocol is handled by a specific frr daemon (e.g. bgpd, ripd or eigrpd)
and can be configured via the frr.conf configuration file. To get started with
BGP, we first need to enable the corresponding daemon `bgpd` in
/etc/frr/daemons by replacing the default `no` with `yes`.

```
...
bgpd=yes
...
```

### BGP for IPv4 networks

In the following configuration example for BGP IPv4, we are going to use the
topology shown below. It consists of two switches and two servers, which will
all act as BGP routers and establish BGP sessions with all of their connected
neighbors. The two servers are not directly connected to each other and both
have a specific subnet configured to their loopback interface, which they will
announce via iBGP to their directly connected switch. The switches are connected
to each other via eBGP and should announce all connected routes they receive
(including the before mentioned subnet on the loopback interface) to their
neighbors. After establishing all BGP sessions, both servers should receive
routes via the two switches as nexthops to the subnets configured on the
loopback interfaces.

```
 +-----------------------------------------+        +--------------------------------------------+
 |                                      +--+        +--+                                         |
 |  switch-1                            |  |        |  |                      switch-2           |
 |                          10.0.0.1/24 |  +--------+  | 10.0.0.2/24                             |
 |                               port54 |  |  eBGP  |  | port54                                  |
 |  10.0.1.1/24                         +--+        +--+                             10.0.2.1/24 |
 |  +---+                                  |        |                                +---+       |
 |  |   | port7                  ASN 65000 |        | ASN 65001                port7 |   |       |
 +--+-+-+----------------------------------+        +--------------------------------+-+-+-------+
      |                                                                                |
      |                                                                                |
      |iBGP                                                                            |iBGP
      |                                                                                |
      |                                                                                |
 +--+-+-+----------------------------------+       +---------------------------------+-+-+-------+
 |  |   | eno7                   ASN 65000 |       |  ASN 65001                 eno7 |   |       |
 |  +---+                    +---+         |       |             +---+               +---+       |
 |  10.0.1.2/24    server-1  | lo|         |       |             | lo|               10.0.2.2/24 |
 |                           +---+         |       |             +---+                           |
 |                           10.0.100.2/32 |       |             10.0.101.2/32                   |
 |                                         |       |                                             |
 |  server-1                               |       |                           server-2          |
 +-----------------------------------------+       +---------------------------------------------+
```

Setting up the IP addresses on the interfaces on the switches and servers
according to the diagram above, can also be done with frr by using zebra (which
is enabled by default).

The /etc/frr/frr.conf file has the protocol specific configurations, where the
routing information is set up. This routing information entails all the
necessary next-hops, route announcements, and route-filters needed to achieve
the configuration.

The parameter `router bgp <AS>` is the first configuration for bgpd, where we
define the Autonomous System (AS) for the routing daemon.  The `router id`
parameter is used to identify the router we are configuring and has to be
unique within the system.  The `neighbor` lines configure the remote peer and
how to connect to it. The `remote-as`, must match the AS number for the remote
endpoint.  The option `ebgp-multihop 1` is used to ensure that the connection
between the two routers from different AS (otherwise it would be iBGP and hops
do not matter in iBGP connections) is a direct one without any additonal
routing hops. For more detailed descriptions and all available options please
refer to the frr documentation linked on top.

The last lines on the configuration file specify the networks that should be
announced to the other peer. The other node will receive these networks, and
learn the appropriate routes to the next-hop. For this example we just use
`redistribute connected` to announce all routes from all connected routers.

`switch-1 /etc/frr/frr.conf`

```
interface port7
  ip address 10.0.1.1/24
interface port54
  ip address 10.0.0.1/24

router bgp 65000
bgp router-id 10.0.1.1
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor left ebgp-multihop 1
  neighbor 10.0.1.2 peer-group left
  neighbor switch peer-group
  neighbor switch remote-as 65001
  neighbor switch ebgp-multihop 1
  neighbor 10.0.0.2 peer-group switch
  redistribute connected
```

`switch-2 /etc/frr/frr.conf`

```
interface port7
  ip address 10.0.2.1/24
interface port54
  ip address 10.0.0.2/24

router bgp 65001
bgp router-id 10.0.2.1
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor left ebgp-multihop 1
  neighbor 10.0.2.2 peer-group left
  neighbor switch peer-group
  neighbor switch remote-as 65000
  neighbor switch ebgp-multihop 1
  neighbor 10.0.0.1 peer-group switch
  redistribute connected
```

`server-1 /etc/frr/frr.conf`

```
interface eno7
  ip address 10.0.1.2/24
interface lo
  ip address 10.0.100.2/32

router bgp 65000
bgp router-id 10.0.1.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor left ebgp-multihop 1
  neighbor 10.0.1.1 peer-group left
  network 10.0.100.2/32
```

`server-2 /etc/frr/frr.conf`

```
interface eno7
  ip address 10.0.2.2/24
interface lo
  ip address 10.0.101.2/32

router bgp 65001
bgp router-id 10.0.2.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor left ebgp-multihop 1
  neighbor 10.0.2.1 peer-group left
  network 10.0.101.2/32
```

After configuring all servers and switches, frr needs to be restarted to pick
up the new configuration and apply it. Baseboxd will then pick up these changes
via the corresponding netlink events and forward this configuration do the ASIC.

The routes received on the switch can be checked by using `ip route` and the
corresponding flowtable entries can be seen when running `client_flowtable_dump
30` (where 30 is the table for unicast routing entries)

For further debugging using `vtysh`, please refer to the official frr
documentation.

### BGP for IPv6 networks

In the following configuration example for BGP IPv6, we are going to use the
topology shown below. It consists of two switches and two servers, which will
all act as BGP routers and establish BGP sessions with all of their connected
neighbors. The two servers are not directly connected to each other and both
have a specific subnet configured to their loopback interface, which they will
announce via iBGP to their directly connected switch. The switches are connected
to each other via eBGP and should announce all connected routes they receive
(including the before mentioned subnet on the loopback interface) to their
neighbors. After establishing all BGP sessions, both servers should receive
routes via the two switches as nexthops to the subnets configured on the
loopback interfaces.

```
 +-------------------------------------------------------------+        +----------------------------------------------------------------+
 |                                                          +--+        +--+                                                             |
 |                                                          |  |        |  |                                                             |
 |                                       2001:0db8::0001/64 |  +--------+  | 2001:0db8::0002/64                                          |
 |                 switch-1                          port54 |  |  eBGP  |  | port54                   switch-2                           |
 |  2001:0db8:0000:0001::0001/64                            +--+        +--+                              2001:0db8:0000:0002::0001/64   |
 |  +---+                                                      |        |                                                    +---+       |
 |  |   | port7                                      ASN 65000 |        | ASN 65001                                    port7 |   |       |
 +--+-+-+------------------------------------------------------+        +----------------------------------------------------+-+-+-------+
      |                                                                                                                        |
      |                                                                                                                        |
      |iBGP                                                                                                                    |iBGP
      |                                                                                                                        |
      |                                                                                                                        |
 +--+-+-+------------------------------------------------------+       +-----------------------------------------------------+-+-+-------+
 |  |   | eno7                                       ASN 65000 |       |  ASN 65001                                     eno7 |   |       |
 |  +---+                                                      |       |                                                     +---+       |
 |  2001:0db8:0000:0001::0002/64                               |       |                                  2001:0db8:0000:0002::0002/64   |
 |                           +---+                             |       |             +---+                                               |
 |                 server-1  | lo|                             |       |             | lo|            server-2                           |
 |                           +---+                             |       |             +---+                                               |
 |                           2001:0db8:0000:0100::0001/64      |       |             2001:0db8:0000:0101::0001/64                        |
 |                                                             |       |                                                                 |
 +-------------------------------------------------------------+       +-----------------------------------------------------------------+
```

Setting up the IP addresses on the interfaces on the switches and servers
according to the diagram above, can also be done with frr by using zebra (which
is enabled by default).

The /etc/frr/frr.conf file has the protocol specific configurations, where the
routing information is set up. This routing information entails all the
necessary next-hops, route announcements, and route-filters needed to achieve
the configuration.

The parameter `router bgp <AS>` is the first configuration for bgpd, where we
define the Autonomous System (AS) for the routing daemon.  The `router id`
parameter is used to identify the router we are configuring and has to be
unique within the system.  The `neighbor` lines configure the remote peer and
how to connect to it. The `remote-as`, must match the AS number for the remote
endpoint.  The option `ebgp-multihop 1` is used to ensure that the connection
between the two routers from different AS (otherwise it would be iBGP and hops
do not matter in iBGP connections) is a direct one without any additional
routing hops. For more detailed descriptions and all available options please
refer to the frr documentation linked on top.

For ipv6 routing only configurations (like the one show above), we use the `no
bgp default ipv4-unicast` option to specifically disable ipv4 peering.
The last lines on the configuration file specify the networks that should be
announced to the other peer. The other node will receive these networks, and
learn the appropriate routes to the next-hop. For this example we use
`redistribute connected` to announce all routes from all connected routers on
the switches and only announce the specifc network configured on the loopback
interface in the servers.

`switch-1 /etc/frr/frr.conf`

```
interface port7
  ip address 2001:0db8:0000:0001::0001/64
interface port54
  ip address 2001:0db8::0001/64

router bgp 65000
bgp router-id 1.1.1.1
  timers bgp 1 3
  no bgp default ipv4-unicast
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor 2001:0db8:0000:0001::0002 peer-group left
  address-family ipv6
    neighbor 2001:0db8:0000:0001::0002 activate
  exit-address-family
  neighbor switch peer-group
  neighbor switch remote-as 65001
  neighbor 2001:0db8::0002 peer-group switch
  address-family ipv6
    redistribute connected
    neighbor 2001:0db8::0002 activate
  exit-address-family
```

`switch-2 /etc/frr/frr.conf`

```
interface port7
  ip address 2001:0db8:0000:0002::0001/64
interface port54
  ip address 2001:0db8::0002/64

router bgp 65001
bgp router-id 2.2.2.2
  timers bgp 1 3
  no bgp default ipv4-unicast
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor 2001:0db8:0000:0002::0002 peer-group left
  address-family ipv6
    neighbor 2001:0db8:0000:0002::0002 activate
  exit-address-family
  neighbor switch peer-group
  neighbor switch remote-as 65000
  neighbor 2001:0db8::0001 peer-group switch
  address-family ipv6
    redistribute connected
    neighbor 2001:0db8::0001 activate
  exit-address-family
```

`server-1 /etc/frr/frr.conf`

```
interface eno7
  ip address 2001:0db8:0000:0001::0002/64
interface lo
  ip address 2001:0db8:0000:0100::0001/64

router bgp 65000
bgp router-id 3.3.3.3
  timers bgp 1 3
  no bgp default ipv4-unicast
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor  2001:0db8:0000:0001::0001 peer-group left
  address-family ipv6
    neighbor  2001:0db8:0000:0001::0001 activate
  exit-address-family
  address-family ipv6
    network 2001:0db8:0000:0100::0001/64
  exit-address-family
```

`server-2 /etc/frr/frr.conf`

```
interface eno7
  ip address 2001:0db8:0000:0002::0002/64
interface lo
  ip address 2001:0db8:0000:0101::0001/64

router bgp 65001
bgp router-id 4.4.4.4
  timers bgp 1 3
  no bgp default ipv4-unicast
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor  2001:0db8:0000:0002::0001 peer-group left
  address-family ipv6
    neighbor  2001:0db8:0000:0002::0001 activate
  exit-address-family
  address-family ipv6
    network 2001:0db8:0000:0101::0001/64
  exit-address-family
```

After configuring all servers and switches, frr needs to be restarted to pick
up the new configuration and apply it. Baseboxd will then pick up these changes
via the corresponding netlink events and forward this configuration do the ASIC.

The routes received on the switch can be checked by using `ip route` and the
corresponding flowtable entries can be seen when running `client_flowtable_dump
30` (where 30 is the table for unicast routing entries)

For further debugging using `vtysh`, please refer to the official frr
documentation.

### Unnumbered BGP

BISDN Linux 6.0 introduces support for unnumbered BGP.

Unnumbered BGP establishes BGP sessions over IPv6 link-local addresses, so the
links do not need manually assigned IP addresses. FRR negotiates the extended next
hop capability ([RFC 8950](https://tools.ietf.org/html/rfc8950.html), formerly
RFC 5549), which allows IPv4 prefixes to be advertised with IPv6 next hops.

This example exchanges IPv4 loopback routes over IPv6 link-local BGP sessions.
Only the server loopbacks have IPv4 addresses; all links use IPv6 link-local
addresses. Each server announces its loopback prefix to its directly connected
switch over iBGP. The switches exchange these prefixes over eBGP,
allowing the servers to reach each other's loopbacks without assigning IPv4
addresses to any of the links.

```
 +-------------------------------------------------------------+        +----------------------------------------------------------------+
 |                                                          +--+        +--+                                                             |
 |                                                          |  |        |  |                                                             |
 |  router-id 1.1.1.1                          (link-local) |  +--------+  | (link-local)                            router-id 2.2.2.2   |
 |                 switch-1                          port54 |  |  eBGP  |  | port54                   switch-2                           |
 |  (link-local)                                            +--+        +--+                                            (link-local)     |
 |  +---+                                                      |        |                                                    +---+       |
 |  |   | port7                                      ASN 65000 |        | ASN 65001                                    port7 |   |       |
 +--+-+-+------------------------------------------------------+        +----------------------------------------------------+-+-+-------+
      |                                                                                                                        |
      |                                                                                                                        |
      |iBGP                                                                                                                    |iBGP
      |                                                                                                                        |
      |                                                                                                                        |
 +--+-+-+------------------------------------------------------+       +-----------------------------------------------------+-+-+-------+
 |  |   | eno7                                       ASN 65000 |       |  ASN 65001                                     eno7 |   |       |
 |  +---+                                                      |       |                                                     +---+       |
 |  (link-local)                                               |       |                                                  (link-local)   |
 |                           +---+                             |       |             +---+                                               |
 |                 server-1  | lo|                             |       |             | lo|            server-2                           |
 |                           +---+                             |       |             +---+                                               |
 |                           10.0.100.2/32                     |       |             10.0.101.2/32                                       |
 |                                                             |       |                                                                 |
 +-------------------------------------------------------------+       +-----------------------------------------------------------------+
```

As in the previous examples, the switches connect through `port54`, and each
server connects through `eno7` to `port7` on its switch. Switch-1 and server-1
use ASN 65000, while switch-2 and server-2 use ASN 65001.

Configure link-local addressing with systemd-networkd on all links.
The `IPv6AcceptRA=no` setting prevents networkd from installing a
default route from the router advertisements sent by FRR.

`switch-1 and switch-2 /etc/systemd/network/10-port7.network`

```ini
[Match]
Name=port7

[Network]
LinkLocalAddressing=ipv6
IPv6AcceptRA=no
```

`switch-1 and switch-2 /etc/systemd/network/10-port54.network`

```ini
[Match]
Name=port54

[Network]
LinkLocalAddressing=ipv6
IPv6AcceptRA=no
```

`server-1 and server-2 /etc/systemd/network/20-eno7.network`

```ini
[Match]
Name=eno7

[Network]
LinkLocalAddressing=ipv6
IPv6AcceptRA=no
```

In FRR, an unnumbered neighbor is identified by its interface name instead
of an IP address. The `left` peer group configures the iBGP session over
`port7` on the switches and `eno7` on the servers. On each switch, the `port54`
neighbor is the eBGP session to the other switch. The `ipv4 unicast` address
family carries the server loopback prefixes using IPv6 link-local next hops.

Each switch sets `neighbor left next-hop-self` when advertising routes to its
server. A next hop learned from the other switch is a link-local address on that
switch's `port54` and is not reachable from the server, so each switch replaces
it with its own link-local address on `port7`. Only the servers originate
prefixes with `network`; the switches announce the routes learned through BGP.

The switches have no IPv4 address, so `bgp router-id` has to be set explicitly
on them. The servers use their loopback address as router ID.

`switch-1 /etc/frr/frr.conf`

```
router bgp 65000
  bgp router-id 1.1.1.1
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor port7 interface peer-group left
  neighbor port54 interface remote-as 65001
  address-family ipv4 unicast
    neighbor left activate
    neighbor left next-hop-self
    neighbor port54 activate
  exit-address-family
```

`switch-2 /etc/frr/frr.conf`

```
router bgp 65001
  bgp router-id 2.2.2.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor port7 interface peer-group left
  neighbor port54 interface remote-as 65000
  address-family ipv4 unicast
    neighbor left activate
    neighbor left next-hop-self
    neighbor port54 activate
  exit-address-family
```

`server-1 /etc/frr/frr.conf`

```
interface lo
  ip address 10.0.100.2/32

router bgp 65000
  bgp router-id 10.0.100.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor eno7 interface peer-group left
  address-family ipv4 unicast
    neighbor left activate
    network 10.0.100.2/32
  exit-address-family
```

`server-2 /etc/frr/frr.conf`

```
interface lo
  ip address 10.0.101.2/32

router bgp 65001
  bgp router-id 10.0.101.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor eno7 interface peer-group left
  address-family ipv4 unicast
    neighbor left activate
    network 10.0.101.2/32
  exit-address-family
```

Apply the network configuration and restart FRR on all four nodes:

```shell
networkctl reload
systemctl restart frr
```

The links should have IPv6 link-local addresses and no IPv4 or global IPv6
addresses. Allow a few seconds for the link-local addresses to appear.

To check traffic between the server loopbacks, run on server-1:

```shell
ping -I 10.0.100.2 -c 3 10.0.101.2
```

Check the BGP sessions with `vtysh -c "show bgp ipv4 unicast summary"`.
Routes to the server loopbacks should use IPv6 link-local next hops.

The routes received on the switch can be checked by using `ip route` and the
corresponding flowtable entries can be seen when running `client_flowtable_dump
30` (where 30 is the table for unicast routing entries)

For further debugging using `vtysh`, please refer to the official frr
documentation.
