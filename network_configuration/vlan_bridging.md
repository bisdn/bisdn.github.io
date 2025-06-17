---
title: VLAN Bridging and Trunking (802.1q or 802.1ad)
parent: Network Configuration
---

# VLAN Bridging (802.1q or 802.1ad)

## Introduction

In Linux systems, a bridge acts like a virtual switch that interconnects
different network interfaces on the same host. Linux bridging supports VLAN
filtering, which allows the configuration of different VLANs on the bridge
ports.

The traditional bridging mode in Linux, created without VLAN filtering, accepts
only one VLAN per bridge and the ports attached must have VLAN-subinterfaces
configured. For a large number of VLANS, this poses an issue with scalability,
which is the motivation for the usage of VLAN-aware bridges.

**WARNING**: baseboxd supports only the VLAN-aware bridge mode. Creating
traditional bridges will result in undefined behavior.
{: .label .label-red }

Only a single bridge is supported inside Basebox and due to the nature of
VLAN-Aware bridges only one is necessary. The following subsections contain
instructions for configuring bridges using [iproute2](#iproute2) and
[systemd-networkd](#systemd-networkd).

QinQ VLANs, or 802.1ad is an extension to the VLAN standard that allows multiple
VLAN tags to be attached to a single frame. Using stacked VLANs, providers are
able to bundle traffic tagged with different VLAN into a single Service tag.

Similarly to 802.1q bridging, it is possible to configure 802.1ad VLANs using
[iproute2](#iproute2) or [systemd-networkd](#systemd-networkd).

**WARNING**: Any bridge configured to forward VLAN traffic with either protocol
802.1q or 802.1ad will only forward traffic of the selected VLAN protocol type.
{: .label .label-red }

## iproute2

### 802.1q

Bridge creation is done with the following command:

```bash
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1
ip link set ${BRIDGE} up
```

The vlan_filtering 1 flag sets the VLAN-aware bridge mode. The default, or
primary VLAN identifier (PVID) is used to tag incoming traffic that does not
have any VLAN tag. By using the vlan_default_pvid flag on creation, this value
can be adjusted (default=1), with 0 as the special meaning to not set any
default PVID and configure no VLANs on ports by default.

To enslave interfaces to bridges refer to the following commands. The management
interface should not be bridged with the rest of the baseboxd interfaces.

```bash
# port A
ip link set ${PORTA} master ${BRIDGE}
ip link set ${PORTA} up

# port B
ip link set ${PORTB} master ${BRIDGE}
ip link set ${PORTB} up
```

Configuring the VLANs on the bridge member ports is done with the following
command

```bash
bridge vlan add vid ${vid} dev ${PORTA}
```

While removing VLANs from ports is handled via the subsequent

```bash
bridge vlan del vid ${vid} dev ${PORTA}
```

The bridge interface itself is also treated like a port, and needs its own VLAN
configuration for any VLANs you want to receive on it. It is not required for
simple forwarding between ports. Like other ports, it gets the default PVID
assigned when configured.

When configuring further VLANs on the bridge interface the `self` flag is
required

```bash
bridge vlan add vid ${vid} dev ${BRIDGE} self
```

While removing VLANs works like other ports

```bash
bridge vlan del vid ${vid} dev ${BRIDGE}
```

Finally, detaching the ports from the bridge is done via

```bash
ip link set ${PORTA} nomaster
```

### 802.1ad

Creation of the 802.1ad bridge is done with the following commands.

```bash
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1 vlan_protocol 802.1ad
ip link set ${BRIDGE} up
```

The rest of the configuration follows the same steps as shown above for the
802.1q bridging section.

## systemd-networkd

### 802.1q

The configuration with systemd-networkd can be done with the following files,
under the /etc/systemd/network directory.

`10-swbridge.netdev`

```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
DefaultPVID=1
VLANFiltering=1
```

For systemd-networkd, files with the .netdev extension specify the configuration
for Virtual Network Devices. Under the [NetDev] section, the Name field
specifies the name for the device to be created, and the Kind parameter
specifies the type of interface that will be created. More information can be
seen under the [systemd-networkd .netdev man
page](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#Supported%20netdev%20kinds).
Under the [Bridge] field, similar parameters as the ones used for iproute2 are
used.

The bridge interface needs to be brought up for basic bridging functionality, so
a basic .network file is required for the bridge itself.

`10-swbridge.network`

```ini
[Match]
Name=swbridge
```

Attaching ports to the bridge and configuring VLANs with systemd-networkd is
also done using .network files. The following example demonstrates how.

`20-port1.network`

```ini
[Match]
Name=port1

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=1
EgressUntagged=1
VLAN=1-10
```

This file would configure a single slave port to the configured bridge.
systemd-networkd allows for matching all ports as well, by using the Name=port\*
alternative, which would match on every baseboxd port, and enslave them all to
the bridge. The VLAN=1-10 will configure the range from VLAN=1 to VLAN=10.
Single values can obviously be configured as well, by specifying just a single
value.

Configuring VLANs on the bridge interface itself is done similarily extending
the above .network file with a `[BridgeVLAN]` block.

`10-swbridge.network`

```ini
[Match]
Name=swbridge

[BridgeVLAN]
PVID=1
EgressUntagged=1
VLAN=1-10
```

### 802.1ad

A `.netdev` file for the bridge needs to be created in `/etc/systemd/network/`,
containing the device type (bridge) and its configurations. Specifically related
to 802.1ad, we configure the bridge VLAN protocol with the `VLANProtocol`
attribute:

`10-swbridge.netdev`

```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
DefaultPVID=0
VLANFiltering=1
VLANProtocol=802.1ad
```

The remaining configurations follow the same steps from the instructions in the
802.1q bridging section above.

# VLAN Trunking

## Introduction

A "trunk port" describes a port that can forward more than one VLAN. We say that
the port is trunked into several VLANs. This enables us to use a single port as
an entry point for all VLANs configured on a switch, instead of one port per
VLAN.

Conversely, an access port is the special case where a trunk port has a single
VLAN as its Native VLAN (PVID) and adds this PVID to all untagged packets it
forwards.

## Example switch with uplink

The example configuration below shows two switches connected with trunk ports.
Both switches are connected to a server via two access ports.
![vlan_trunk_image](/assets/img/vlan_trunk_network.svg)

Note that the both switches are identically configured, so although we only
provide configuration for a single server and a single switch, the configuration
applies to both ``switch1`` and ``switch2``.

PVID=2 and PVID=3 are configured on the access ports ``port2`` and ``port3``
respectively. Additionally egress traffic is untagged on these ports so the
server are not aware of the VLAN.
VLAN=2 and VLAN=3 is set on the trunk port ``port54``.

The configuration for this example can be done with either ``iproute2`` for
testing or systemd-network files for persistency in production
environments.

## iproute2

Bridge creation is done with the following command.

```bash
ip link add name swbridge type bridge vlan_filtering 1 vlan_default_pvid 0
ip link set swbridge up
```

A bridge port will be configured with the default PVID of the bridge, unless
disabled. Since the ports in our example will have different PVIDs, we will
set the bridge's default PVID to none. Only in the case where all ports have
the same PVID, should one set the default PVID on the bridge.

```bash
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

Finally, configuring the VLANs on the bridge member ports is done with the
following commands.

```bash
bridge vlan add vid 2 dev port2 pvid untagged
bridge vlan add vid 3 dev port3 pvid untagged
bridge vlan add vid 2 dev port54
bridge vlan add vid 3 dev port54
```

Removing the configuration can be done with a reboot, or by deleting the bridge.

```bash
ip link del swbridge
```

## systemd-networkd

The configuration with systemd-networkd can be done by placing the following
files, under the /etc/systemd/network directory. The first line of the snippet
is the file name.

The first file creates the bridge without any default PVID configured,
analogous to ``iproute2``

`10-swbridge.netdev`

```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

Bring up the bridge, so forwarding will be enabled

`10-swbridge.network`

```ini
[Match]
Name=swbridge
```

Attaching the access ports ``port2`` and ``port3`` is done as follows

`20-port2.network`

```ini
[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=2
EgressUntagged=2
```

`20-port3.network`

```ini
[Match]
Name=port3

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=3
EgressUntagged=3
```

Configuring PVID for a port will enable the VLAN ID for ingress as well, as
stated in the [documentation for
systemd.network](https://www.freedesktop.org/software/systemd/man/systemd.network.html#PVID=)

The trunk port is created with the following network file.

`20-port54.network`

```ini
[Match]
Name=port54

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=2
VLAN=3
```
