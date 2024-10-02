---
title: Routing Information Protocol (RIP)
parent: Network Configuration
---

# Routing Information Protocol (RIP)

## Introduction

Routing Information Protocol (RIP) is one the oldest routing protocols available to use. While other routing protocols like IS-IS and OSPF are used in more modern applications due to reduced convergence time and improved scalability, RIP is one of the easiest protocols to configure, and small networks can take advantage of the small bandwidth usage and configuration/management simplicity.

**WARNING**: EIGRP is currently only tested for IPv4.

## FRR configuration

Configuring EIGRP in FRR starts by activating the daemon in `/etc/frr/daemons`.

```
ripd=yes
```

Configuring the daemon is done via the `/etc/frr/frr.conf`.

```
router rip
  network 10.1.0.0/24
  network port7
  neighbor 10.0.1.254
```

In the configuration snippet above, the `network` keyword either activates the routing protocol in the interfaces that are configured, like `network INTERFACE` where INTERFACE is a port on the switch; or in the `network NETWORK` case, where RIP will be enabled on interfaces that have matching NETWORKS. The `neighbor ADDRESS` keyword is used when a certain neighbor does not understand multicast, and we form a direct relationship between the two routers.
