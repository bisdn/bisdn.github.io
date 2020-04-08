---
title: Border Gateway Protocol (BGP)
parent: Network Configuration
---

# Border Gateway Protocol

## Introduction

The Border Gateway Protocol (BGP) is a distance-vector routing protocol. It was originally designed to support IPv4 networks in [RFC4721](https://tools.ietf.org/html/rfc4271.html), and later extended to support other protocols, such as IPv6, in [RFC2858](https://tools.ietf.org/html/rfc2858.html). Contrary to OSPF, where its IPv4 and IPv6 are defined in FRR with different daemons/files, the FRR BGP daemon can be configured for both protocols. Its complete documentation for FRR can be found [here](http://docs.frrouting.org/en/latest/bgp.html). 

In this section, we provide examples on how to configure BGP for both [IPv4](#bgp-for-ipv4-networks) and [IPv6](#bgp-for-ipv6-networks) networks in BISDN Linux.

## BGP for IPv4 networks

FRR is configured using files, typically on the /etc/frr/ directory. Each desired protocol has a different configuration file,
where the protocol-specific information can be stored.  This folder will also hold the general configuration files for FRR itself,
like the daemons file, used to set the listening addresses for the protocols and as toggle for configuration of each individual
routing protocol/daemon.

```
zebra=yes
bgpd=yes
ospfd=no
...
vtysh_enable=yes
zebra_options="  -A 127.0.0.1 -s 90000000"
bgpd_options="   -A 127.0.0.1"
...
```

The /etc/frr/bgpd.conf file has the protocol specific configurations, where the routing information is set up. This routing
information entails all the necessary next-hops, route announcements, and route-filters needed to achieve the configuration.

Setting up the IP addresses on the interfaces on the controller according to the diagram above, can be done using iproute2 commands.

### BGP configuration overview

```
router bgp 65000
 bgp router-id 10.0.254.1
 bgp cluster-id 10.0.254.1
 bgp log-neighbor-changes
```

router BGP <AS> is the first configuration for bgpd, where we define the Autonomous System (AS) for the routing daemon.
Router id and cluster id are two parameters used to identify the router we are configuring.

```
neighbor fabric peer-group
neighbor fabric remote-as 65000
neighbor fabric ebgp-multihop 10
neighbor 10.0.254.2 peer-group fabric
```

The neighbor lines specify the remote peer-group we are configuring. The remote-as, must match the AS number for the remote endpoint, enabling iBGP (BGP session across two nodes configured in the same AS) The last line will finally configure the neighbor.

```
network 10.1.0.0/24
network 10.1.1.0/24
network 10.1.2.0/24
network 10.1.3.0/24
network 10.1.4.0/24
network 10.1.5.0/24
```

The last lines on the configuration file specify the networks that must be announced to the other peer. The other node will
receive these networks, and learn the appropriate routes to the next-hop.

### BGP expected result and debugging

BGP expects a connection through the defined neighbors to port 179 by default. The connection status can be checked via the FRR shell vtysh.

The result of vtysh command, show ip bgp sum must be:

```
(vtysh) show ip bgp sum
```

With this command, we see that a neighbor has been successfully learned, and the connection is online and stable.
Debugging the BGP connection might be a tricky process, but guides from [cisco](https://meetings.ripe.net/ripe-44/presentations/ripe44-eof-bgp.pdf).
More information on the BGP neighbors is available via

```
(vtysh) show ip bgp neighbors
```

The iBGP-learned routes may be checked out if correctly installed on the kernel via

```
ip route
```

The final debugging information to confirm must be the switch tables, where we must check if baseboxd has correctly translated
the rules on the kernel to OpenFlow flow mods, via client_flowtable_dump 30. This is the sole command that must *always* be run
on the switch. The previous commands must be run on the controller/switch, depending where baseboxd is running.

## BGP for IPv6 networks

The FRR configuration for BGPv6 is stored in the same file as for the IPv4 BGP configuration, /etc/frr/bgpd.conf. As such, the daemons file will look the same as the file used in the IPv4
configuration.

IPv6 addresses on the router must be manually written, as in the BGPv4 case. The main difference in the BGPv6 case is due to the presence of auto-configuration mechanisms for IP addresses in IPv6, which allows generating a new IP address for the servers interfaces without having to create them manually, for they are derived from the interface’s MAC addresses, and an announced network prefix in a router port. The IPv6 auto-configuration is possible via the zebra.conf configuration, like

```
interface port1
  no shutdown
  no ipv6 nd suppress-ra
  ipv6 nd prefix 2003:db01:1::/64
```

The bgpd.conf file configures routes and next-hops. The most relevant configuration difference to the BGP case is the required configuration for the next-hop address,
where FRR must ensure that we are using the globally configured IP addresses, the ones present on port53, on the image. This is due to the fact that Link-Local address can also be
used to peer across the two Basebox routers, leading to possible errors. This is done via the following configurations.

In the section address-family ipv6:

```
neighbor {{neigh}} route-map set-nexthop in
```

And in another section,

```
route-map set-nexthop permit 10
  set ipv6 next-hop peer-address
  set ipv6 next-hop prefer-global
```

Another useful parameter for BGPv6 is shutting down the default address family for IPv4, this way ensuring that configuration will
tune the BGPv6 parameters, via

```
router bgp 65000
  no bgp default ipv4-unicast
```

### BGPv6 expected result and debugging

The commands and notes mentioned in the BGP (Border Gateway Protocol) section are still relevant for this case.
