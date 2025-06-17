---
title: Enhanced Interior Gateway Routing Protocol (EIGRP)
parent: Network Configuration
---

# Enhanced Interior Gateway Routing Protocol (EIGRP)

## Introduction

The Enhanced Interior Gateway Routing Protocol is a distance-vector routing
protocol that is defined in [RFC 7868](https://tools.ietf.org/html/rfc7868).
The protocol shares routes with other routers in the same Autonomous System. In
contrary to other distance-vector protocols updates to the routing table is
shared over differential updates, instead of transmitting the entire routing
table. This reduces the control traffic on the network and provides faster
convergence for changes in network topology.

**WARNING**: EIGRP is currently only tested for IPv4.

## FRR configuration

Configuring EIGRP in FRR starts by activating the daemon in `/etc/frr/daemons`.

```
eigrpd=yes
```

Then `/etc/frr/frr.conf` can be configured as follows.

```
router eigrp 65000
 network 10.0.0.0/24
```

The interfaces that have addresses matching with the configured network will
then have EIGRP enabled.
