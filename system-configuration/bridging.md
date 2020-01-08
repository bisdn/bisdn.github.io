---
date: '2020-01-07T16:07:30.187Z'
docname: system-configuration/bridging
images: {}
path: /system-configuration-bridging
title: Bridging
nav_order: 8
---

# Bridging

## Introduction

The vlan_filtering 1 flag sets the VLAN-aware bridge mode. The traditional bridging mode in Linux, created without the vlan_filtering flag, accepts only one VLAN per bridge and the ports attached must have VLAN-subinterfaces configured. For a large number of VLANS, this poses an issue with scalability, which is the motivation for the usage of VLAN-aware bridges, where each bridge port will be configured with a list of allowed VLANS.

**WARNING**: baseboxd supports only the VLAN-Aware bridge mode. Creating traditional bridges will result in undefined behavior.

Only a single bridge is supported inside Basebox and due to the nature of VLAN-Aware bridges only one is necessary.

## iproute2

Bridge creation is done with the following command.

```
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1
ip link set ${BRIDGE} up
```

The default, or primary VLAN identifier (PVID) is used to tag incoming traffic that does not have any VLAN tag. By using the vlan_default_pvid flag on creation, this value can be adjusted (default=1).

To enslave interfaces to bridges refer to the following commands. The management interface should not be bridged with the rest of the baseboxd interfaces.

```
# port A
ip link set ${PORTA} master ${BRIDGE}
ip link set ${PORTA} up

# port 2
ip link set ${PORTB} master ${BRIDGE}
ip link set ${PORTB} up
```

Finally, configuring the VLANs on the bridge member ports, and the bridge itself is done with the following commands. The bridge port will inherit the VLANs and PVID from the bridge, unless specifically overwritten. The self flag is required when configuring the VLAN on the bridge interface itself.

```
bridge vlan add vid ${vid} dev ${PORTA}
bridge vlan add vid ${vid} dev ${BRIDGE} self
```

Removing VLANs from ports/ bridges is handled via the subsequent.

```
bridge vlan del vid ${vid} dev ${PORTA}
```

And detaching the ports from the bridge is done via

```
ip link set ${PORTA} nomaster
```

## systemd-networkd

The configuration with systemd-networkd can be done with the following files, under the /etc/systemd/networkd directory.

```
10-swbridge.netdev:

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
DefaultPVID=1
VLANFiltering=1
```

For systemd-networkd, files with the .netdev extension specify the configuration for Virtual Network Devices. Under the [NetDev] section, the Name field specifies the name for the device to be created, and the Kind parameter specifies the type of interface that will be created. More information can be seen under the [systemd-networkd .netdev man page](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#Supported%20netdev%20kinds). Under the [Bridge] field, similar parameters as the ones used for iproute2 are used. To configure VLANs in the Bridge interface, a .network file must be used, as the following example.

```
10-swbridge.network:

[Match]
Name=swbridge

[BridgeVLAN]
PVID=1
EgressUntagged=1
VLAN=1-10
```

Attaching ports to a bridge with systemd-networkd is done similarly, using the .network files. The following example demonstrates how.

```
20-port1.network:

[Match]
Name=port1

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=1
EgressUntagged=1
VLAN=1-10
```

This file would configure a single slave port to the configured bridge. systemd-networkd allows for matching all ports as well, by using the Name=port\* alternative, which would match on every baseboxd port, and enslave them all to the bridge. The VLAN=1-10 will configure the range from VLAN=1 to VLAN=10. Single values can obviously be configured as well, by specifying just a single value.

# QinQ Provider Bridging (802.1ad)

## Introduction

QinQ VLANs, or 802.1ad is an extension to the VLAN standard that allows multiple VLAN tags to be attached to a single frame. Using stacked VLANs, providers are able to bundle traffic tagged with different VLAN into a single Service tag.

**WARNING**: Any bridge configured to forward VLAN traffic with either protocol 802.1Q or 802.1ad will only forward traffic of the selected VLAN protocol type.

## iproute2

Creation of the 802.1ad bridge is done with the following commands.

```
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1 vlan_protocol 802.1ad
ip link set ${BRIDGE} up
```

The rest of the configuration follows the same steps as the Bridging section.
