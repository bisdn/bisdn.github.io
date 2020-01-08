---
date: '2020-01-07T16:07:30.187Z'
docname: system-configuration/ospfv2
images: {}
path: /system-configuration-ospfv-2
title: OSPF (Open Shortest Path First)
nav_order: 11
---

# OSPF (Open Shortest Path First)

OSPF is a link state routing protocol.

## OSPF configuration

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

## OSPF expected result and debugging

Analogous to the previous protocols debugging commands, we can run the following commands to verify the configuration.

```
ip route

(vtysh) show ip ospf sum

(vtysh) show ip ospf neighbors
```
