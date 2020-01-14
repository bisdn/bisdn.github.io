---
title: Virtual Routing and Forwarding
parent: Layer 3
nav_order: 4
---
# Virtual Routing and Forwarding

## Introduction

Virtual Routing and Forwarding (VRF) is a feature in Linux allowing for the separation of routing tables and independent processing of network paths.

Creation of VRFs in Linux is the creation of a network device, which will then serve as a master to the attached interfaces. Currently the VRF functionality is supported only on setups where a Bridge VLAN interface are slave devices to a certain VRF. This feature then extends the Switch VLAN Interface functionality allowing multiple routing tables.

An ID for the routing table for the VRF is used to isolate all routes from the default (host) routing table. IDs can be chosen in the range of 1 to 4294967295 (2^32-1) with the exclusion of 253-255 which are used for the default routing tables.

For more information, consult the VRF documentation inside the Linux Kernel in: [https://www.kernel.org/doc/Documentation/networking/vrf.txt](https://www.kernel.org/doc/Documentation/networking/vrf.txt)

## iproute2

The creation of VRF interfaces is done via the following commands.

```
ip link add ${VRF} type vrf table ${VRF_TABLE_ID}
ip link set ${VRF} up
```

After creation of the VRF device, follow the steps under Switch VLAN Interface to configure a VLAN-aware bridge with the corresponding SVI layer 3 devices. Enslaving these links on the bridge to the VRF is possible with the below commands.

```
ip link set ${BRIDGE}.${BR_VLAN} vrf ${VRF}
ip link set ${BRIDGE}.${BR_VLAN2} vrf ${VRF}
```

Adding IP addresses to the enslaved SVIs must be done after enslavement to the VRFs.

## systemd-networkd

The file responsible to create the VRF device is the .netdev file below.

```
10-red.netdev
[NetDev]
Name=red
Kind=vrf

[VRF]
TableId=2
```

To add a SVI to a VRF, then copy the file to the systemd-networkd directory.

```
20-swbridge10.network:

[Match]
Name=swbridge.10

[Network]
Address=10.0.10.1/24
VRF=red
```


