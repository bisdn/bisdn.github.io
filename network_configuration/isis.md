---
title: Intermediate System to Intermediate System (IS-IS)
parent: Network Configuration
---

# Intermediate System to Intermediate System

## Introduction

IS-IS is an interior gateway protocol (IGP) widely used in large backbone
provider networks and is defined in [ISO/IEC 10589:2002](https://www.iso.org/standard/30932.html).
Within BISDN Linux, IS-IS can be configured and managed with the FRR daemon
[isisd](http://docs.frrouting.org/en/latest/isisd.html).

This section provides an overview on how to configure IS-IS in BISDN Linux.

## IS-IS configuration

To use IS-IS within FRR, the IS-IS daemon `isisd` must first be enabled via the
/etc/frr/daemons file to be automatically started and managed via the
frr.service in systemd.

`/etc/frr/daemons`

```
...
isisd=yes
...
```

The following configuration guide will explain how to configure a simple IS-IS
toplogy containing two switches and two servers, each exchanging routes via
IS-IS like shown below.

```
 +-------------------------------------------------------------+        +----------------------------------------------------------------+
 |                                                          +--+        +--+                                                             |
 |                                                   port54 |  |        |  | port54                                                      |
 |                                              10.0.0.1/24 |  +--------+  | 10.0.0.2/24              switch-2                           |
 |                 switch-1                            L2   |  |  IS-IS |  |   L2                                                        |
 |  10.0.1.1/24                                             +--+        +--+                                                 10.0.2.1/24 |
 |  port7                                                      |        |                                                    port7       |
 |  +---+                                   area 0             |        | area 0                                             +---+       |
 |  |   | L2                                100.100.100.100.00 |        | 100.100.100.101.00                                 |   |  L2   |
 +--+-+-+------------------------------------------------------+        +----------------------------------------------------+-+-+-------+
      |                                                                                                                        |
      |                                                                                                                        |
      |IS-IS                                                                                                                   |IS-IS
      |                                                                                                                        |
      |                                                                                                                        |
 +--+-+-+------------------------------------------------------+       +-----------------------------------------------------+-+-+-------+
 |  |   | L2                                200.200.200.200.00 |       |  200.200.200.201.00                                 |   | L2    |
 |  +---+                                   area 1             |       |  area 2                                             +---+       |
 |  eno7                     +---+                             |       |             +---+                                   eno7        |
 |  10.0.1.2/24    server-1  | lo|                             |       |             | lo|            server-2               10.0.2.2/24 |
 |                           +---+                             |       |             +---+                                               |
 |                           10.0.100.2/32                     |       |             10.0.101.2/32                                       |
 |                                                             |       |                                                                 |
 +-------------------------------------------------------------+       +-----------------------------------------------------------------+
```

To allow all switches and servers to communicate with each other, we first have
to make sure all directly connected elements share at least one common network
for each connection. In the topology shown above, these networks will be
`10.0.0.0/24`, `10.0.1.0/24` and `10.0.2.0/24`. The goal of this example is to
exchange routes for the two networks `10.0.100.2/32` and `10.0.101.2/32`
configured on each of the loopback interfaces of the servers between all
involved elements via IS-IS.

To configure IS-IS between all elements shown in the topology above, we need to
assign unique network entity titles in ISO format ("net") to all of them and
configure which interfaces we want to use within the IS-IS routing domain. The
examples shown below create an IS-IS router named BISDN, add the needed ports
to this router and configure level-2 circuits between all adjacent elements.
Additionally they add the `lo` interface to the BISDN router on the servers, so
that the route to the /32 address configured on it will also be announced to
all other routers.


`switch-1: /etc/frr/frr.conf`

```
interface port7
  ip address 10.0.1.1/24
interface port54
  ip address 10.0.0.1/24

router isis BISDN
  is-type level-1-2
  net 49.0001.0100.0100.0100.00
interface port54
  ip route isis BISDN
  isis circuit-type level-2
  isis network point-to-point
interface port7
  ip router isis BISDN
  isis circuit-type level-2
```

`switch-2: /etc/frr/frr.conf`

```
interface port7
  ip address 10.0.2.1/24
interface port54
  ip address 10.0.0.2/24

router isis BISDN
  is-type level-1-2
  net 49.0001.0100.0100.0101.00
interface port54
  ip route isis BISDN
  isis circuit-type level-2
  isis network point-to-point
interface port7
  ip router isis BISDN
  isis circuit-type level-2
```

`server-1: /etc/frr/frr.conf`

```
interface eno7
  ip address 10.0.1.2/24
interface lo
  ip address 10.0.100.2/32

router isis BISDN
  is-type level-1-2
  net 49.0001.0200.0200.0200.0200.00
interface eno7
  ip router isis BISDN
  isis circuit-type level-2
interface lo
  ip router isis BISDN
```

`server-2: /etc/frr/frr.conf`

```
interface eno7
  ip address 10.0.2.2/24
interface lo
  ip address 10.0.101.2/32

router isis BISDN
  is-type level-1-2
  net 49.0001.0200.0200.0200.0201.00
interface eno7
  ip router isis BISDN
  isis circuit-type level-2
interface lo
  ip router isis BISDN
```

After this configuration has been applied and the frr.service was restarted,
server-1 and server-2 should both have received routes via IS-IS similar to the
ones shown below:

`IS-IS routes on server-1`

```
10.0.0.0/24 via 10.0.1.1 dev eno7 proto isis metric 20
10.0.1.0/24 dev eno7 proto kernel scope link src 10.0.1.2
10.0.2.0/24 via 10.0.1.1 dev eno7 proto isis metric 20
10.0.101.2 via 10.0.1.1 dev eno7 proto isis metric 20
```

With these routes, both servers should now be able to reach the /32 network
configured on the loopback interface of the corresponding other server while
using the two in-between routers switch-1 and switch-2 as hops.

For all possible configuration options within isisd in FRR, please refer to the
official FRR documentation [here](http://docs.frrouting.org/en/latest/isisd.html)

## Cisco Interoperability

When connecting Cisco routers and switches running BISDN Linux and FRR with ISIS, it is essential to correctly configure
the `metric-style` setting. Per default, the Cisco Routers have the `metric-style narrow` configuration,
while FRR chooses the wide metrics. Refer to [CISCO docs](https://www.cisco.com/c/en/us/support/docs/ip/integrated-intermediate-system-to-intermediate-system-is-is/13795-is-is-ip-config.html) for further documentation on configuring Cisco routers with ISIS. For specific information on `metric-syle` configurations, refer to [CISCO](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/iproute_isis/command/irs-cr-book/irs-l1.html#wp1681001735) and [FRR](http://docs.frrouting.org/en/latest/isisd.html#clicmd-metric-style[narrow|transition|wide]).

