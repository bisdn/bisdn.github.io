---
title: VLAN Bridging Trunk
parent: Network Configuration
---

# Trunk VLAN

## Introduction

A "trunk port" describes a port that can forward more than one VLAN. We say that
the port is trunked into several VLANs. This enables us to use a single port as
an entry point for all VLANs configured on a switch, instead of one port per
VLAN.

Conversely, an access port is the special case where a trunk port has a single
VLAN as its Native VLAN (PVID) and adds this PVID to all untagged packets it forwards.

## Example switch with uplink
The example configuration below shows two switches connected with trunk ports.
Both switches are connected to a server via two access ports.
![vlan_trunk_image](/assets/img/vlan_trunk_network.svg)

Note that the both switches are identically configured, so although we only
provide configuration for a single server and a single switch, the configuration
applies to both ``switch1`` and ``switch2``.

PVID=2 and PVID=3 are configured on the access ports ``port2`` and ``port3``
respectively. Additionally egress traffic is ungagged on these ports so the
server are not aware of the VLAN.
VLAN=2 and VLAN=3 is set on the trunk port ``port54``.

The configuration for this example can be done with either ``iproute2`` for
testing or systemd-network files for persistency in production
environments.
## iproute2

Bridge creation is done with the following command.

```
ip link add name swbridge type bridge vlan_filtering 1 vlan_default_pvid none
ip link set swbridge up
```

A bridge port will inherit the VLANs and PVID from the bridge, unless
specifically overwritten. Since the ports which will be connected to the bridge
have different PVIDs, the default will be set to none. Only in the case where
all ports have the same PVID, should one set the default PVID on the bridge.

```
# port2
ip link set port2 master swbridge 
ip link set port2 up

# port3
ip link set port3 master swbridge
ip link set port3 up

# port54
ip link set port54 master swbridge
ip link set port54 up
```

Finally, configuring the VLANs on the bridge member ports, and the bridge itself is done with the following commands.  The self flag is required when configuring the VLAN on the bridge interface itself.

```
bridge vlan add vid 2 dev port2 pvid
bridge vlan add vid 3 dev port3 pvid
bridge vlan add vid 2 dev port54 untagged
bridge vlan add vid 3 dev port54 untagged
bridge vlan add vid 2 dev swbridge self
bridge vlan add vid 3 dev swbridge self
```

Removing the configuration can be done with a reboot, or by deleting the bridge.
```
ip link del swbridge
```

## systemd-networkd

The configuration with systemd-networkd can be done by placing the following files,
under the /etc/systemd/networkd directory. The first line of the snippet is
the file name.
The first two files create the bridge and add VLAN 2 and 3 to it, completely
analogous to ``iproute2``

```
10-swbridge.netdev:

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

```
10-swbridge.network:

[Match]
Name=swbridge

[BridgeVLAN]
VLAN=2
VLAN=3
```

Attaching the access ports ``port2`` and ``port3`` is done as follows

```
20-port2.network:

[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=2
EgressUntagged=2
```

```
20-port3.network:

[Match]
Name=port3

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=3
EgressUntagged=3
```
Configuring PVID for a port will enable the VLAN ID for ingress as well, as
stated in the [documentation for systemd.network](https://www.freedesktop.org/software/systemd/man/systemd.network.html#PVID=)

The trunk port is created with the following network file.

```
20-port54.network:

[Match]
Name=port54

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=2
VLAN=3
```
