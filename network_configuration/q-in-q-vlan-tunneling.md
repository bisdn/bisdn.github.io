---
title: Q-in-Q VLAN Tunneling
parent: Network Configuration
---

# Q-in-Q VLAN Tunneling (802.1q in 802.1ad)

## Introduction

Q-in-Q VLAN tunneling, also known as 802.1Q tunneling or VLAN stacking, is a
technique that allows service providers to encapsulate customer VLAN-tagged
traffic within an additional VLAN tag as it traverses the provider network.
This method enables the transparent transport of multiple customer VLANs
(C-VLANs) over a single service provider VLAN (S-VLAN), effectively expanding
the VLAN space and allowing overlapping VLAN IDs from different customers to
coexist without conflict.

In practice, Q-in-Q tunneling works by adding an extra 802.1Q tag to Ethernet
frames received from customer networks. The original customer VLAN tag is
preserved, while the outer tag-assigned by the service provider-segregates
traffic within the provider’s infrastructure. This double-tagging approach is
particularly valuable for Metro Ethernet and data center environments, where it
facilitates secure and scalable Layer 2 connectivity between geographically
dispersed customer sites or tenants.

## systemd-networkd

For the example configuration documented, we assume a network topology like
shown below.

```
+-------------------------------------------+   +-------------------------------------------+
| switch-1                                  |   | switch-2                                  |
|              swbridge                     |   |                     swbridge              |
|         +-------------+------------------+|   |+------------------+-----------+           |
|         |             |   port54.33      ||   ||    port54.33     |           |           |
|+------------------+   +------------------+|   |+------------------+   +------------------+|
||     port2        |   |   port54         ||   ||    port54        |   |    port2         ||
++------------------+---+------------------++   ++------------------+---+------------------++
          |                       |                       |                     |
          |                       |                       |                     |
          |                       +-----------------------+                     |
          | 802.1q tagged               double tagged             802.1q tagged |
          |                           802.1q in 802.1ad                         |
          |                                                                     |
++-----------------------------+                             +----------+-------+----------++
||   eno2           |          |                             |          |    eno2          ||
|+------------------+          |                             |          +------------------+|
||   eno2.12        |          |                             |          |    eno2.12       ||
|+------------------+          |                             |          +------------------+|
|       10.0.0.1/24            |                             |                 10.0.0.2/24  |
|                              |                             |                              |
| server-1                     |                             | server-2                     |
+------------------------------+                             +------------------------------+
```

Within this topology, the two servers each send single tagged traffic (one
802.1q tag) towards the switch that they are connected to. Both switches then
forward this traffic across an 802.1q VLAN bridge (called `swbridge`). The
switches are connected to each other via `port54`. Both switches define a VLAN
interface with protocol 802.1ad (q-in-q) on top of `port54`, which adds (egress)
or removes (ingress) an additional VLAN with the id 33 when forwarding traffic.
This VLAN interface `port54.33` is attached to the `swbridge` and part of the
VLAN domain 12. Whenever traffic with the VLAN id 12 is forwarded from one
switch to the other, the `egress` on `port54.33` adds an additional q-in-q VLAN
tag (802.1ad) with id 33 on top of the already existing 802.1q tag with id 12
(which was added by the server). Whenever traffic with VLAN id 33 is forwarded
from the `port54` towards the bridge (and further towards the server), the
`ingress` of `port54.33` removes the VLAN tag with the id 33 before forwarding
it to the `swbridge`.

To configure Q-in-Q VLAN tunneling with systemd-networkd for a topology like
shown above, please follow the steps for all switches and servers documented
below.

For all steps, please create the corresponding files (e.g. `10-swbridge.netdev`
or `20-port54.33.network`) in `/etc/systemd/network/` on either the
corresponding switch or server with the content shown below the filename.

### Switch configuration

Since the configuration on both switches is exactly the same, the steps below
can be executed on both of them without any modifications.

Create a switch bridge named `swbridge` with no default VLAN and allow it to
forward and filter 802.1q tagged traffic.

`10-swbridge.netdev`
```ini
[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
DefaultPVID=none
VLANFiltering=1
VLANProtocol=802.1q
```

Automatically set the switch bridge `swbridge` administrative state to up.

`10-swbridge.network`
```ini
[Match]
Name=swbridge
```

Attach `port2` to the `swbridge` and allow it to forward VLAN traffic with the
VLAN id 12 from (and to) the server across the bridge.

`20-port2.network`
```ini
[Match]
Name=port2

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=12
```

Automatically set `port54` (connected to another switch) up and associate it to
the VLAN interface `port54.33`.

`10-port54.network`
```ini
[Match]
Name=port54

[Network]
VLAN=port54.33
```

Define the VLAN interface `port54.33` on top of `port54` and allow it to tag
(egress) and untag (ingress) traffic with an 802.1ad VLAN tag with the id 33.

`20-port54.33.netdev`
```ini
[NetDev]
Name=port54.33
Kind=vlan

[VLAN]
Id=33
Protocol=802.1ad
```

Attach the VLAN interface `port54.33` to the `swbridge` and allow it to forward
VLAN traffic with the VLAN id 12 across the bridge.

`20-port54.33.network`
```ini
[Match]
Name=port54.33

[Network]
Bridge=swbridge

[BridgeVLAN]
VLAN=12
```

### Server configuration

Since the only difference between the configuration on `server-1` and `server-2`
is the IP address assigned to the VLAN interface `eno2.12`, the steps below can
be executed on both servers while only modifying the `Address` parameter in the
last step.

Automatically set `eno2` (connected to the switch) up and associate it to the
VLAN interface `eno2.12`.

`20-eno2.network`
```ini
[Match]
Name=eno2

[Network]
VLAN=eno2.12
```

Define the VLAN interface `eno2.12` on top of `eno2` and allow it to tag
(egress) and untag (ingress) traffic with an 802.1q VLAN tag with the id 12.

`20-eno2.12.netdev`
```ini
[NetDev]
Name=eno2.12
Kind=vlan

[VLAN]
Id=12
Protocol=802.1q
```

Automatically set `eno2.12` up and assign the IP address `10.0.0.1` from a
`/24` network to it. This configuration is intended for `server-1` from the
topology shown above and the IP address has to be changed to `10.0.0.2` for
`server-2`.

`30-eno2.12.network`
```ini
[Match]
Name=eno2.12

[Network]
Address=10.0.0.1/24
```

### Switch and Server

To apply all configuration on both switches and servers, you need to `restart`
`systemd-networkd` on all devices with the command shown below.

```bash
sudo systemctl restart systemd-networkd
```

### Validate

To validate the configuration is working as expected, you can send a simple
`ping` between the two servers, across the link and through the 802.1ad VLAN
tunnel between the switches.

- on server-1:

```bash
ping 10.0.0.2 -I 10.0.0.1
```

To watch the double tagged ICMP packets traverse the link between the switches,
you can use
[switch_tcpdump](/tools/ofdpa_client_tools#traffic-capture-with-tcpdump) on
either of the switches on `port54` like shown below.

- on switch-1:

```bash
root@switch-1:/etc/systemd/network# switch_tcpdump --inPort port54 -vne --stdout
Set ACL table rule to redirect port54 ingress traffic to us
Running tcpdump -i port54 -vne
tcpdump: listening on port54, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:54:00.493201 0c:c4:7a:9c:29:f9 > 0c:c4:7a:9c:27:d1, ethertype 802.1Q-QinQ (0x88a8), length 106: vlan 33, p 0, ethertype 802.1Q (0x8100), vlan 12, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id 16629, offset 0, flags [DF], proto ICMP (1), length 84)
    10.0.0.1 > 10.0.0.2: ICMP echo request, id 1480, seq 114, length 64
08:54:01.517133 0c:c4:7a:9c:29:f9 > 0c:c4:7a:9c:27:d1, ethertype 802.1Q-QinQ (0x88a8), length 106: vlan 33, p 0, ethertype 802.1Q (0x8100), vlan 12, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id 17637, offset 0, flags [DF], proto ICMP (1), length 84)
    10.0.0.1 > 10.0.0.2: ICMP echo request, id 1480, seq 115, length 64
08:54:02.541202 0c:c4:7a:9c:29:f9 > 0c:c4:7a:9c:27:d1, ethertype 802.1Q-QinQ (0x88a8), length 106: vlan 33, p 0, ethertype 802.1Q (0x8100), vlan 12, p 0, ethertype IPv4 (0x0800), (tos 0x0, ttl 64, id 17720, offset 0, flags [DF], proto ICMP (1), length 84)
    10.0.0.1 > 10.0.0.2: ICMP echo request, id 1480, seq 116, length 64
```

The `switch_tcpdump` command above, shows the `egress` packets traversing
`port54` of switch-1 towards `port54` of switch-2. The outer tag of each packet
is shown as `ethertype 802.1Q-QinQ (0x88a8)` with `vlan 33`, while the inner tag
is of `ethertype 802.1Q (0x8100)` with `vlan 12`. Since we only dump the
`egress` of `port54` on switch-1, we only see the `ICMP echo request` packets.
