---
title: Open Shortest Path First (OSPF)
parent: Network Configuration
---

# Open Shortest Path First

## Introduction

The Open Shortest Path First (OSPF) protocol is a link state routing protocol. Its IPv4 networking version is specified as [OSPFv2](https://tools.ietf.org/html/rfc2328) and the IPv6 version is defined as [OSPFv3](https://tools.ietf.org/html/rfc5340). 
Both versions can be configured using FRR and their full documentation is available for both [OSPFv2](http://docs.frrouting.org/en/latest/ospfd.html) and [OSPFv3](http://docs.frrouting.org/en/latest/ospf6d.html) versions, respectively.

This section provides an overview on how to configure both versions on BISDN Linux.

## OSPFv2 configuration

OSPF must first be enabled in /etc/frr/daemons file. The relevant files for this test case must then be
configured, /etc/frr/zebra.conf and /etc/frr/osfpd.conf.

```
zebra=yes
bgpd=no
ospfd=yes
...
vtysh_enable=yes
zebra_options="  -A 127.0.0.1 -s 90000000"
```

The zebra file will set IP addresses on the interfaces with the configuration snippet. It is not required that the same tools are used, just that the system is correctly configured for the connectivity tests.

```
interface port1
  no shutdown
  ip address 10.1.1.1/24
```

Regarding /etc/frr/osfpd.conf, the configuration here must specify the point-to-point parameter in the
interface specific section, to enable the protocol on the port53 link between the two Basebox routers.
The redistribute connected command is a “smart” flag by FRR, that will redistribute every network configured
on the router.

```
interface port53
  ip ospf mtu-ignore
  ip ospf network point-to-point
!
router ospf
      ospf router-id {{router_id}}
      redistribute connected
      network 10.0.254.0/24 area 0.0.0.1
exit
```

### OSPF expected result and debugging

Analogous to the previous protocols debugging commands, we can run the following commands to verify the configuration.

```
ip route

(vtysh) show ip ospf sum

(vtysh) show ip ospf neighbors
```

## OSPFv3

OSPFv3 must first be enabled in /etc/frr/daemons file. The relevant files for this test case must then be
configured, /etc/frr/zebra.conf and /etc/frr/osfp6d.conf.

```
zebra=yes
bgpd=no
ospf6d=yes
...
vtysh_enable=yes
zebra_options="  -A 127.0.0.1 -s 90000000"
...
```

The zebra file will configure IP addresses on the interfaces, with the configuration snippet. The following configurations allow setting up the Router neighboring discover packets and IP address auto-configuration.

```
interface port1
  no shutdown
  no ipv6 nd suppress-ra
  ipv6 nd prefix 2001:db8:1::/64
```

Regarding /etc/frr/ospf6d.conf, the configuration here must specify the point-to-point parameter in the
interface specific section, to enable the protocol on the port53 link between the two Basebox routers.
The redistribute connected command is a “smart” flag by FRR, that will redistribute every network configured
on the router.

```
interface port53
  ipv6 ospf6 mtu-ignore
  ipv6 ospf6 network point-to-point
!
router ospf6
      ospf6 router-id {{router_id}}
      interface port53 area 10.10.10.10
      redistribute connected
exit
```

### OSPFv3 expected result and debugging

Analogous to the previous protocols debugging commands, we can run the following commands to verify the configuration.

```
(vtysh) show ip ospf sum

(vtysh) show ip ospf neighbors

ip route
```
