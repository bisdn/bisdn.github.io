---
title: Virtual Routing and Forwarding (VRF)
parent: Network Configuration
---

# Virtual Routing and Forwarding (VRF)

## Introduction

Virtual Routing and Forwarding (VRF) is a feature in Linux allowing for the separation of routing tables and independent processing of network paths.

The creation of VRF entries in Linux consists of creating a network device, which will then serve as a master to the attached interfaces. Currently the VRF functionality is supported only on setups where a Bridge VLAN interface are slave devices to a certain VRF entry. This feature then extends the Switch VLAN Interface functionality allowing multiple routing tables.

An ID for the routing table for the VRF entry is used to isolate all routes from the default (host) routing table. IDs can be chosen in the range of 1 to 4294967295 (2^32-1) with the exclusion of 253-255 which are used for the default routing tables.

For more information, consult the VRF documentation inside the Linux Kernel in: [https://www.kernel.org/doc/Documentation/networking/vrf.txt](https://www.kernel.org/doc/Documentation/networking/vrf.txt)

VRF can be configured using either [iproute2](#iproute2) or [systemd-networkd](#systemd-networkd). The following subsections provide an example on how to setup a VRF entry named "red" with ID 10 between two networks, as seen in the figure below:

![vrf_example](/assets/img/network_vrf_example.svg)

## iproute2

The creation of VRF interfaces is done via the following commands.

```
ip link add ${VRF} type vrf table ${VRF_TABLE_ID}
ip link set ${VRF} up
```

After creation of the VRF device, follow the steps under Switch VLAN Interface (SVI) to configure a VLAN-aware bridge with the corresponding SVI layer 3 devices. Enslaving these links on the bridge to the VRF is possible with the below commands.

```
ip link set ${BRIDGE}.${BR_VLAN} vrf ${VRF}
ip link set ${BRIDGE}.${BR_VLAN2} vrf ${VRF}
```

Adding IP addresses to the enslaved SVIs must be done after enslavement to the VRFs.

## systemd-networkd

The file responsible to create the VRF device is the .netdev file below:

```
10-red.netdev
[NetDev]
Name=red
Kind=vrf

[VRF]
TableId=10
```

Considering the example topology given above, two SVIs are required, i.e. one per VLAN. Both need to be listed in the bridge network file:

```
10-swbridge.network
[Match]
Name=swbridge

[BridgeVLAN]
VLAN=10
VLAN=20

[Network]
VLAN=swbridge.10
VLAN=swbridge.20
```

Each SVI needs to be specified by creating a .netdev and a .network file. The following example assigns IP 10.0.10.2 to a SVI using VID 10 and VRF entry "red":

```
20-swbridge10.netdev
[NetDev]
Name=swbridge.10
Kind=vlan

[VLAN]
Id=10

20-swbridge10.network
[Match]
Name=swbridge.10

[Network]
Address=10.0.10.1/24
VRF=red
```

Similarly, a SVI is created for VID 20:

```
20-swbridge20.netdev
[NetDev]
Name=swbridge.20
Kind=vlan

[VLAN]
Id=20

20-swbridge20.network
[Match]
Name=swbridge.20

[Network]
Address=10.0.20.1/24
VRF=red
```

As a last step on the switch, ports 2 and 3 need to be added to the bridge. This is done by creating a .network file for each port:

```
20-port2.network
[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=10

20-port3.network
[Match]
Name=port3

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=20
```

This configuration is then applied and persisted after restarting systemd-networkd:

```
sudo systemctl restart systemd-networkd
```
