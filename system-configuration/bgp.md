---
date: '2020-01-07T16:07:30.187Z'
docname: system-configuration/bgp
images: {}
path: /system-configuration-bgp
title: BGP (Border Gateway Protocol)
---

# BGP (Border Gateway Protocol)

Leveraging FRR as the routing daemon, the BGP tests will ensure the correct interaction between two controllers and two servers.

## BGP configuration

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

## BGP configuration overview

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

## BGP expected result and debugging

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
