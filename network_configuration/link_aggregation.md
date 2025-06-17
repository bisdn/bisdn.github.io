---
title: Link Aggregation (LAG/Bonding)
parent: Network Configuration
---

# Link Aggregation

## Introduction

Link Aggregation is used to combine multiple physical network links into one
logical bond to aggregate bandwidth and/or provide redundancy. There are
numerous names for link aggregation including teaming, bundling and trunking,
but to align with the default term used in the systemd-networkd context, we
will use bonding to refer to it in this documentation. For more details about
bonding in Linux, please refer to the official [kernel documentation](https://www.kernel.org/doc/Documentation/networking/bonding.txt).

## Suported bonding modes

BISDN Linux currently supports bonding interfaces (excluding the management
interface) in the bond modes `balanced-rr`, `active-backup` and `802.3.ad`. The
following table illustrates the support for each mode in BISDN Linux supported
switches.

```
|               | 802.3ad LACP | Active-Backup | RoundRobin |
|---------------|--------------|---------------|------------|
| agema-ag5648  |       X      |       X       |      X     |
| agema-ag7648  |       X      |       X       |      -     |
| accton-as4610 |       X      |       X       |      -     |
```

- `balanced-rr`: is one of the simplest bonding configurations and provides
  aggregated bandwidth, but no redundancy;
- `active-backup`: provides only redundancy, but does not aggregate the
  bandwidth of the links used;
- `802.3ad`: Used in most data center bonding use cases (which is also often
  referred to as `LACP` bonding). `802.3ad` is used to achieve bandwidth
  aggregation as well as failover redundancy at the same time. In this bond mode,
  the `Link Aggregation Control Protocol` (LACP) is used to monitor the link
  state out-of-band while distributing all outgoing packets over all active
  links.

In this section, we provide examples on how to configure bonding using
[iproute2](#bonding-configuration-with-iproute2) and
[systemd-networkd](#bonding-configuration-with-systemd-networkd) networks in
BISDN Linux.

Please note, that configuring
[PoE](../platform_configuration/power_over_ethernet.md#power-over-ethernet-poe)
must be done on the physical bonded slave interfaces.
[Auto-Negotiation](../platform_configuration/auto_negotiation.md#enabling-auto-negotiation)
configuration is also applied only to these interfaces.
{: .label .label-yellow }

## Example bonding configuration topology

In the following configuration examples, we are going to use the topology shown
below. It consists of two switches which are directly connected to each other
on port 52 and 54. These two interfaces are then bonded using bond mode
`802.3.ad` to achieve redundancy and bandwidth aggregation at the same time.
The created bond is called `bond2` on each side.

Additionally, each switch has port 7 and 8 bonded the same way into `bond1`.
These links are directly connected to servers, which are considered source and
sink for this scenario.
To be able to send traffic between the two servers, all bonds on the switches
are attached to a bridge called `swbridge`.

The servers themselves also use LACP to create `bond1` out of their interfaces
`eno7` and `eno8`.
Each `bond1` interface on the servers gets an IP address that should be
reachable from the opposite server via the two switches in between.

```
 +-------------------------------------------+   +-------------------------------------------+
 | switch-1      +----------+                |   | switch-2      +----------+                |
 |               | swbridge |                |   |               | swbridge |                |
 |               +---+---+--+                |   |               +---+---+--+                |
 |          +--------+   +---------+         |   |          +--------+   +---------+         |
 |     +----+----+            +----+----+    |   |     +----+----+            +----+----+    |
 |     |  bond1  |            |  bond2  |    |   |     |  bond2  |            |  bond1  |    |
 |     ++------+-+            ++------+-+    |   |     ++------+-+            ++------+-+    |
 |      |      |               |      |      |   |      |      |               |      |      |
 |+-----+-+  +-+-----+   +-----+-+  +-+-----+|   |+-----+-+  +-+-----+   +-----+-+  +-+-----+|
 || port7 |  | port8 |   | port52|  | port54||   || port54|  | port52|   | port7 |  | port8 ||
 ++---+---+--+---+---+---+---+---+--+---+---++   ++---+---+--+---+---+---+--+----+--+---+---++
      |          |           |          +-------------+          |          |           |
      |          |           |                                   |          |           |
      |          |           +-----------------------------------+          |           |
      |          |                                                          |           |
      |          |                                                          |           |
      |          |                                                          |           |
 ++---+---+--+---+---+----------+                             +----------+--+----+--+---+---++
 || eno7  |  | eno8  |          |                             |          | eno7  |  | eno8  ||
 |+-----+-+  +--+----+          |                             |          +-----+-+  +--+----+|
 |      |       |               |                             |                |       |     |
 |    +-+-------+--+            |                             |              +-+-------+--+  |
 |    |  bond1     |            |                             |              |  bond1     |  |
 |    +------------+            |                             |              +------------+  |
 |       10.0.3.1/24            |                             |                 10.0.3.2/24  |
 |                              |                             |                              |
 |                     server-1 |                             |                     server-2 |
 +------------------------------+                             +------------------------------+
```

## Bonding configuration with iproute2

To configure the scenario described and shown above, we first create the two
bond devices themselves on both switches (all commands have to be run with root
privileges):

```
ip link add bond1 type bond
ip link add bond2 type bond
```

After the bonds are created, we set the mode to 802.3ad (LACP):
```
ip link set bond1 type bond mode 802.3ad
ip link set bond2 type bond mode 802.3ad
```

To enslave the links to their corresponding bonds, we first set them down and
then update their configuration by setting their master to the bond we created
before:
```
# configure switch to server link
ip link set port7 down
ip link set port7 master bond1
ip link set port8 down
ip link set port8 master bond1
# configure switch to switch link
ip link set port52 down
ip link set port52 master bond2
ip link set port54 down
ip link set port54 master bond2
```

To allow traffic forwarding between the two bonds we created, we create a
bridge and attach them to it:
```
ip link add name swbridge type bridge vlan_filtering 1 vlan_default_pvid 1
ip link set swbridge up
ip link set bond1 master swbridge
ip link set bond2 master swbridge
```

Finally we set the bonds up, which will also bring up the interfaces enslaved
to them:
```
ip link set bond1 up
ip link set bond2 up
```

To configure the servers, we can follow the exact same steps and use identical
commands:
```
ip link add bond1 type bond
ip link set bond1 type bond mode 802.3ad
# configure server to switch link
ip link set eno7 down
ip link set eno7 master bond1
ip link set eno8 down
ip link set eno8 master bond1
ip link set bond1 up
```

After configuring both switches and both servers with the commands shown above,
we can now assign IP addresses to the bond interfaces on the servers and start
pinging each other:
```
# on server-1
ip address add 10.0.3.1/24 dev bond1
```
```
# on server-2
ip address add 10.0.3.2/24 dev bond1
```

With these two addresses assigned, both servers should now be able to reach
each other.

## Bonding configuration with systemd-networkd

To configure the scenario described and shown above, we first create the two
bond devices themselves on both switches by creating corresponding .netdev
files for systemd-networkd (to create these files, you need root privileges):

`/etc/systemd/network/20-bond1.netdev`
```ini
[NetDev]
Name=bond1
Kind=bond
[Bond]
Mode=802.3ad
```

`/etc/systemd/network/20-bond2.netdev`
```ini
[NetDev]
Name=bond2
Kind=bond
[Bond]
Mode=802.3ad
```

To enslave the links to their corresponding bonds, we set their network
configuration to match on the name of the bond we created before:

`/etc/systemd/network/30-port7.network`
```ini
[Match]
Name=port7
[Network]
Bond=bond1
```
`/etc/systemd/network/30-port8.network`
```ini
[Match]
Name=port8
[Network]
Bond=bond1
```
`/etc/systemd/network/30-port52.network`
```ini
[Match]
Name=port52
[Network]
Bond=bond2
```
`/etc/systemd/network/30-port54.network`
```ini
[Match]
Name=port54
[Network]
Bond=bond2
```

To allow traffic forwarding between the two bonds we created, we create a
bridge and attach them to it:

`/etc/systemd/network/10-swbridge.network`
```ini
[Match]
Name=swbridge
```
`/etc/systemd/network/10-swbridge.netdev`
```ini
[NetDev]
Name=swbridge
Kind=bridge
[Bridge]
DefaultPVID=1
VLANFiltering=1
```
`/etc/systemd/network/20-bond1.network`
```ini
[Match]
Name=bond1
[Network]
Bridge=swbridge
```
`/etc/systemd/network/20-bond2.network`
```ini
[Match]
Name=bond2
[Network]
Bridge=swbridge
```

To apply all of this configuration, we just restart systemd-networkd on the
switches.

```
systemctl restart systemd-networkd
```

To configure the servers, we can follow the same structure for creating the
systemd-networkd configuration files:

`/etc/systemd/network/20-bond1.netdev`
```ini
[NetDev]
Name=bond1
Kind=bond
[Bond]
Mode=802.3ad
```
`/etc/systemd/network/30-eno7.network`
```ini
[Match]
Name=eno7
[Network]
Bond=bond1
```
`/etc/systemd/network/30-eno8.network`
```ini
[Match]
Name=eno8
[Network]
Bond=bond1
```

After creating all configuration on both switches and both servers with the
commands shown above, we can now assign IP addresses to the bond interfaces on
the servers and start pinging each other:

`server-1: /etc/systemd/network/20-bond1.network`
```ini
[Match]
Name=bond1
[Network]
Address=10.0.3.1/24
```
`server-2: /etc/systemd/network/20-bond1.network`
```ini
[Match]
Name=bond1
[Network]
Address=10.0.3.2/24
```

To apply all of this configuration, we just restart systemd-networkd on the
servers.
```
systemctl restart systemd-networkd
```

With these two addresses assigned, both servers should now be able to reach
each other.
