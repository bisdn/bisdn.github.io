---
title: Border Gateway Protocol (BGP)
parent: Network Configuration
---

# Border Gateway Protocol

## Introduction

The Border Gateway Protocol (BGP) is a distance-vector routing protocol. It was originally designed to support IPv4 networks in [RFC4721](https://tools.ietf.org/html/rfc4271.html), and later extended to support other protocols, such as IPv6, in [RFC2858](https://tools.ietf.org/html/rfc2858.html). Contrary to OSPF, where its IPv4 and IPv6 are defined in FRR with different daemons/files, the FRR BGP daemon can be configured for both protocols. Its complete documentation for FRR can be found [here](http://docs.frrouting.org/en/latest/bgp.html). 

In this section, we provide examples on how to configure BGP for both [IPv4](#bgp-for-ipv4-networks) and [IPv6](#bgp-for-ipv6-networks) networks in BISDN Linux.

## BGP configuration overview

The FRR configuration files can be found in the /etc/frr/ directory. Each
routing protocol is handled by a specific frr daemon (e.g. bgpd, ripd or eigrpd)
and can be configured via a specific configuration file. To get started with
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

`switch-1 /etc/frr/zebra.conf`
```
interface port7
  ip address 10.0.1.1/24
interface port54
  ip address 10.0.0.1/24
```

`switch-2 /etc/frr/zebra.conf`
```
interface port7
  ip address 10.0.2.1/24
interface port54
  ip address 10.0.0.2/24
```

`server-1 /etc/frr/zebra.conf`
```
interface eno7
  ip address 10.0.1.2/24
interface lo
  ip address 10.0.100.2/32
```

`server-2 /etc/frr/zebra.conf`
```
interface eno7
  ip address 10.0.2.2/24
interface lo
  ip address 10.0.101.2/32
```

The /etc/frr/bgpd.conf file has the protocol specific configurations, where the
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

`switch-1 /etc/frr/bgpd.conf`
```
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

`switch-2 /etc/frr/bgpd.conf`
```
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

`server-1 /etc/frr/bgpd.conf`
```
router bgp 65000
bgp router-id 10.0.1.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65000
  neighbor left ebgp-multihop 1
  neighbor 10.0.1.1 peer-group left
  network 10.0.100.2/32
```

`server-2 /etc/frr/bgpd.conf`
```
router bgp 65001
bgp router-id 10.0.2.2
  timers bgp 1 3
  neighbor left peer-group
  neighbor left remote-as 65001
  neighbor left ebgp-multihop 1
  neighbor 10.0.2.1 peer-group left
  network 10.0.101.2/32
```

The last lines on the configuration file specify the networks that should be
announced to the other peer. The other node will receive these networks, and
learn the appropriate routes to the next-hop. For this example we just use
`redistribute connected` to announce all routes from all connected routers.

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

`switch-1 /etc/frr/zebra.conf`
```
interface port7
  ip address 2001:0db8:0000:0001::0001/64
interface port54
  ip address 2001:0db8::0001/64
```

`switch-2 /etc/frr/zebra.conf`
```
interface port7
  ip address 2001:0db8:0000:0002::0001/64
interface port54
  ip address 2001:0db8::0002/64
```

`server-1 /etc/frr/zebra.conf`
```
interface eno7
  ip address 2001:0db8:0000:0001::0002/64
interface lo
  ip address 2001:0db8:0000:0100::0001/64
```

`server-2 /etc/frr/zebra.conf`
```
interface eno7
  ip address 2001:0db8:0000:0002::0002/64
interface lo
  ip address 2001:0db8:0000:0101::0001/64
```

The /etc/frr/bgpd.conf file has the protocol specific configurations, where the routing information is set up. This routing
information entails all the necessary next-hops, route announcements, and route-filters needed to achieve the configuration.

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

`switch-1 /etc/frr/bgpd.conf`
```
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

`switch-2 /etc/frr/bgpd.conf`
```
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

`server-1 /etc/frr/bgpd.conf`
```
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

`server-2 /etc/frr/bgpd.conf`
```
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

For ipv6 routing only configurations (like the one show above), we use the `no
bgp default ipv4-unicast` option to specifically disable ipv4 peering.
The last lines on the configuration file specify the networks that should be
announced to the other peer. The other node will receive these networks, and
learn the appropriate routes to the next-hop. For this example we use
`redistribute connected` to announce all routes from all connected routers on
the switches and only announce the specifc network configured on the loopback
interface in the servers.

After configuring all servers and switches, frr needs to be restarted to pick
up the new configuration and apply it. Baseboxd will then pick up these changes
via the corresponding netlink events and forward this configuration do the ASIC.

The routes received on the switch can be checked by using `ip route` and the
corresponding flowtable entries can be seen when running `client_flowtable_dump
30` (where 30 is the table for unicast routing entries)

For further debugging using `vtysh`, please refer to the official frr
documentation.
