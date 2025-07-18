---
title: VxLAN (Virtual Extensible Local Area Network)
parent: Network Configuration

---

# VxLAN

## Introduction

Virtual eXtensible LAN (VXLAN) is a network overlay encapsulation protocol that
aims to extend and distribute layer 2 networks on top of layer 3 topologies.
Using a 12-bit Virtual Network Identifier (VNI) it allow to separate about 16
million logical network domains.

The official VXLAN documentation can be found in
[RFC 7348](https://datatracker.ietf.org/doc/html/rfc7348)

**WARNING**: baseboxd does not yet support multicast groups for establishing
communication among multiple VXLAN Tunnel Endpoints (VTEPs), only unicast is
supported. This means you can not use the `group` key in the `VXLAN`
section as documented in
[systemd-netdev](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#Group=)
{: .label .label-yellow }

**WARNING**: baseboxd does not yet support VXLAN on bonded interfaces.
{: .label .label-yellow }

**WARNING**: The Accton AS4610 platform does not have VxLAN support. See our
[Limitations page](/limitations.html#No-VxLAN-support-on-Accton-AS4610) for more
information.
{: .label .label-red }

## Sample VxlAN configuration

```
+-----------------------------------------------+         +-----------------------------------------------+
|                       switch-1                |         |    switch-2                                   |
|   +--------------+                   +--------+         +--------+                   +------------+     |
|   | vxlan50000   +-------------------+ port54 +---------+ port54 +-------------------+ vxlan50000 |     |
|   ++-------------+    192.168.0.1/24 +--------|  vxlan  |--------+  192.168.0.2/24   +--------+---+     |
|    |                                          |         |                                     |         |
|    | VLAN 300                                 |         |                           LAN 300   |         |
|    |                                          |         |                                     |         |
|   ++-------------+                            |         |                            +--------+-----+   |
|   | swbridge     |                            |         |                            | swbridge     |   |
|   ++-------------+                            |         |                            +--------+-----+   |
|    | VLAN 300                                 |         |                           LAN 300   |         |
|    |     |                                    |         |                                |    |         |
|    |     |                                    |         |                                |    |         |
|    |     |                                    |         |                                |    |         |
|    | Untag VLAN                               |         |                          Untag VLAN |         |
|  +-+------+                                   |         |                               +-----+----+    |
|  | port2  |                                   |         |                               | port2    |    |
+--+-+-+----------------------------------------+         +-----------------------------------+-+-+-------+
```

The configuration give below will create a VXLAN overlay with VNI=50000 between
`port54` on `switch-1` and `port54` on `switch-2`. The layer 2 domain containing
`port2` and `port2` bridged on the swbridge on switch-1 and switch-2 is extended
via the before mentioned VXLAN overlay network with the VNI 50000.

## systemd-networkd

The configuration with systemd-networkd can be done with the following files.

Create bridge `swbridge` with no `DefaultPVID`.

`switch-1 /etc/systemd/network/20-swbridge.netdev`

```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

Tag `swbridge` with `VLAN=300` and set it up.

`switch-1 /etc/systemd/network/20-swbridge.network`

```ini
[Match]
Name=swbridge

[BridgeVLAN]
VLAN=300
```

Add VLAN tag `VLAN=300` on `port2` incoming traffic, untag the outgoing one,
attach it to `swbridge` and set it up.

`switch-1 /etc/systemd/network/10-port2.network`

```ini
[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=300
EgressUntagged=300
```

Add ip address 192.168.0.1/24 to `port54`, define it as underlying interface for
netdev vxlan50000 (created below) and set it up.

`switch-1 /etc/systemd/network/10-port54.network`

```ini
[Match]
Name=port54

[Network]
VXLAN=vxlan50000
Address=192.168.0.1/24
```

Create netdev `vxlan50000` for VXLAN with the VNI 50000 and set local and remote
VXLAN Tunnel Endpoints(VTEPs).

`switch-1 /etc/systemd/network/300-vxlan50000.netdev`

```ini
[NetDev]
Name=vxlan50000
Kind=vxlan

[VXLAN]
VNI=50000
DestinationPort=4789
Local=192.168.0.1
Remote=192.168.0.2
```

Forward VLAN tagged traffic with `VLAN=300` on `vxlan50000` and attach it to
`swbridge`. Bind `port54` as the carrier device to align the behaviour and
state (up/down) of `vxlan50000` to its underlying interface.
`DestinationPort=4789` sets the destination UDP port to follow the IANA standard
from [rfc7348](https://datatracker.ietf.org/doc/html/rfc7348). If no port is
set systemd will use the default Linux kernel value 8472.

**WARNING**: baseboxd currently sets the local VTEP Termination port to 4789,
which means that every remote VTEP must use `DestinationPort=4789`.
{: .label .label-yellow }

`switch-1 /etc/systemd/network/300-vxlan50000.network`

```ini
[Match]
Name=vxlan50000

[Network]
BindCarrier=port54
Bridge=swbridge

[BridgeVLAN]
VLAN=300
```

The configuration files for `switch2` are identical to those of `switch1`
with the execption that the IPv4 addresses for the VTEP, Remote and Local will
switch. Therefore the files below are shown without additional explanation.

`switch-2 /etc/systemd/network/20-swbridge.netdev`

```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
DefaultPVID=none
```

`switch-2 /etc/systemd/network/20-swbridge.network`

```ini
[Match]
Name=swbridge

[BridgeVLAN]
VLAN=300
```

`switch-2 /etc/systemd/network/10-port2.network`

```ini
[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
PVID=300
EgressUntagged=300
```

`switch-2 /etc/systemd/network/10-port54.network`

```ini
[Match]
Name=port54

[Network]
VXLAN=vxlan50000
Address=192.168.0.2/24
```

`switch-2 /etc/systemd/network/300-vxlan50000.netdev`

```ini
[NetDev]
Name=vxlan50000
Kind=vxlan

[VXLAN]
VNI=50000
DestinationPort=4789
Local=192.168.0.2
Remote=192.168.0.1
```

`switch-2 /etc/systemd/network/300-vxlan50000.network`

```ini
[Match]
Name=vxlan50000

[Network]
BindCarrier=port54
Bridge=swbridge

[BridgeVLAN]
VLAN=300
```

Restart systemd-networkd or reboot the switches to apply network configuration.
