---
title: VxLAN (Virtual Extensible Local Area Network)
parent: Network Configuration

---

# VxLAN

## Introduction
Virtual eXtensible LAN (VXLAN) is a network overlay encapsulation protocol that aims to extend and distribute layer 2 networks on top of layer 3 topologies. Using a 12-bit Virtual Network Identifier (VNI) it allow to separate about 16 million logical network domains.

The official VXLAN documentation can be found in
[RFC 7348](https://datatracker.ietf.org/doc/html/rfc7348)

**WARNING**: baseboxd does not yet support multicast groups for establishing
communication among multiple VXLAN Tunnel Endpoints (VTEPs), only unicast is
supported. This means you can not use the ``group`` key in the ``VXLAN``
section as documented in
[systemd-netdev](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#Group=)
{: .label .label-yellow }

**WARNING**: The Accton AS4610 platform does not have VxLAN support. See our
[Limitations page](/limitations.md#No-VxLAN-support-on-Accton-AS4610) for more
information.
{: .label .label-red }

## Sample VxlAN configuration

#  +-----------------------------------------------+         +-----------------------------------------------+
#  |                       switch1                 |         |    switch2                                    |
#  |   +--------------+                   +--------+         +--------+                   +------------+     |
#  |   | vxlan50000   +-------------------+ port_b +---------+ port_c +-------------------+ vxlan50000 |     |
#  |   ++-------------+    192.168.0.1/24 +--------|  vxlan  |--------+  192.168.0.2/24   +--------+---+     |
#  |    |                                          |         |                                     |         |
#  |    | VLAN 300                                 |         |                           LAN 300   |         |
#  |    |                                          |         |                                     |         |
#  |   ++-------------+                            |         |                            +--------+-----+   |
#  |   | swbridge     |                            |         |                            | swbridge     |   |
#  |   ++-------------+                            |         |                            +--------+-----+   |
#  |    | VLAN 300                                 |         |                           LAN 300   |         |
#  |    |     |                                    |         |                                |    |         |
#  |    |     |                                    |         |                                |    |         |
#  |    |     |                                    |         |                                |    |         |
#  |    | Untag VLAN                               |         |                          Untag VLAN |         |
#  |  +-+------+                                   |         |                               +-----+----+    |
#  |  | port_a |                                   |         |                               | port_d   |    |
#  +--+-+-+----------------------------------------+         +-----------------------------------+-+-+-------+

The configuration give below will create a VXLAN overlay with VNI=50000 between
``port_b`` on ``switch1`` and ``port_c`` on ``switch2``. ``port_a`` and
``port_d`` will have layer 2 connectivity.

## systemd-networkd
The configuration with systemd-networkd can be done with the following files,
simply add them to the ``/etc/systemd/networkd`` directory on ``switch1``.

Create bridge ``swbridge``, tag it on ``vlan=300`` and set it up.
```
20-swbridge.netdev:

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

```
20-swbridge.network:

[Match]
Name=swbridge

[BridgeVLAN]
VLAN=300
```

Tag ``vlan=300`` on ``port_a``, attach it to ``swbridge`` and set it up.
```
10-port_a.network:

[Match]
Name=port_a

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=300
EgressUntagged=300
```

Add ``vxlan=50000`` to ``port_c``, configure an IPv4 address, and set it up.
```
10-port_b.network:

[Match]
Name=port_b

[Network]
VXLAN=vxlan50000
Address=192.168.0.1/24
```

Create vxlan ``vxlan50000`` and set local and remote VXLAN Tunnel
Endpoints(VTEPs).
```
300-vxlan50000.netdev:

[NetDev]
Name=vxlan50000
Kind=vxlan

[VXLAN]
VNI=50000
DestinationPort=4789
Local=192.168.0.1
Remote=192.168.0.2
```

Allow VLAN tagged traffic with ``VLAN=300`` on ``vxlan50000`` and attach it to
``swbridge``. Set ``port_b`` to be the BindCarrier to bind the behaviour and
state (up/down) of ``vxlan50000`` to its underlying interface.
``DestinationPort`` configures the destination UDP port to the IANA standard.
If no port is set systemd will use the default Linux kernel value 8472.

**WARNING**: baseboxd currently sets the local VTEP Termination port to 4789,
which means that every remote VTEP must use ``DestinationPort``=4789.
{: .label .label-yellow }

```
300-vxlan50000.network:

[Match]
Name=vxlan50000

[Network]
BindCarrier=port_b
Bridge=swbridge

[BridgeVLAN]
VLAN=300
```

The configuration files for ``switch2`` are identical to those of ``switch1``
with the exception of port names (``port_a`` and ``port_b`` become ``port_d``
and ``port_c``, and the IPv4 addresses for the VTEP, Remote and Local will
switch. Therefore the files below are shown without additional explanation.

```
20-swbridge.netdev:

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

```
20-swbridge.network:

[Match]
Name=swbridge

[BridgeVLAN]
VLAN=300
```

```
10-port_d.network:

[Match]
Name=port_d

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=300
EgressUntagged=300
```

```
10-port_c.network:

[Match]
Name=port_c

[Network]
VXLAN=vxlan50000
Address=192.168.0.2/24
```

```
300-vxlan50000.netdev:

[NetDev]
Name=vxlan50000
Kind=vxlan

[VXLAN]
VNI=50000
DestinationPort=4789
Local=192.168.0.2
Remote=192.168.0.1
MacLearning=True
```

```
300-vxlan50000.network:

[Match]
Name=vxlan50000

[Network]
BindCarrier=port_b
Bridge=swbridge

[BridgeVLAN]
VLAN=300
```

Reboot the switches(recommended) or restart systemd-networkd for the
configuration to take effect.
