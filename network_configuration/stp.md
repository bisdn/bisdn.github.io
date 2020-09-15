---
title: Spanning Tree Protocol (STP)
parent: Network Configuration
---

# Spanning Tree Protocol (STP)

## Introduction

The Spanning Tree Protocol (STP) is meant to build loop-less topologies in Layer 2 networks. It works by distributively creating network paths without loops that could be harmful in case of e.g. flooding broadcast messages, by disabling (blocking) ports in the configured bridges. This document shows how to configure the STP implementation available in Linux.

**WARNING**: BISDN Linux currently supports standard STP (IEEE Standard 802.1d) and RSTP (IEEE Standard 802.1w). In most modern network topologies RSTP is used because it provides significantly faster recovery in case of topology changes. To configure RSTP you *have* to use the packaged [mstpd](https://github.com/mstpd/mstpd) instead of the default STP implementation in the Linux kernel.
{: .label .label-yellow }

## STP Configuration Instructions

The STP configuration examples below assume the following topology. Throughout all examples given here, only the switch configuration side is shown.

![Topology](/assets/img/stp-topology.png)

An STP-enabled bridge can be created using iproute2 with the following command:

```
ip link add name swbridge type bridge vlan_filtering 1 stp_state 1
```

or by copying following systemd-networkd configuration files into the /etc/systemd/networkd directory and restarting the `systemd-networkd` systemd-service.
```
10-swbridge.netdev:

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
VLANFiltering=1
STP=1
```

```
10-swbridge.network:

[Match]
Name=swbridge
```

The necessary commands for configuring and attaching the ports to the bridge are documented here: [VLAN Bridging](/network_configuration/vlan_bridging.md#vlan-bridging-8021q).

## STP operation

We can see the ports that are configured in bridges, along with their STP state, priority, and cost, with the following command:

```
agema-ag4610:~$ bridge link
15: port2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master swbridge state forwarding priority 32 cost 2
16: port3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master swbridge state forwarding priority 32 cost 2
```

After setting up the bridge and bridge ports, the STP state on the bridge can be managed over the `brctl` utility. The following example shows the output of a `brctl` command:

```
agema-ag4610:/home/basebox# brctl showstp swbridge
swbridge
 bridge id              8000.62e79c6a4489
 designated root        8000.62e79c6a4489
 root port                 0                    path cost                  0
 max age                  20.00                 bridge max age            20.00
 hello time                2.00                 bridge hello time          2.00
 forward delay            15.00                 bridge forward delay      15.00
 ageing time              15.00
 hello timer               0.00                 tcn timer                  0.00
 topology change timer     0.00                 gc timer                   1.37
 flags


port7 (1)
 port id                8001                    state                  blocking
 designated root        8000.62e79c6a4489       path cost                  2
 designated bridge      8000.62e79c6a4489       message age timer          0.00
 designated port        8001                    forward delay timer        0.00
 designated cost           0                    hold timer                 0.00
 flags

port8 (2)
 port id                8002                    state                  blocking
 designated root        8000.62e79c6a4489       path cost                  2
 designated bridge      8000.62e79c6a4489       message age timer          0.00
 designated port        8002                    forward delay timer        0.00
 designated cost           0                    hold timer                 0.00
 flags

```

# Rapid Spanning Tree (RSTP)

## Introduction 

Meant as an improvement to the original STP standard, RSTP improves Spanning Tree convergence after network topology changes. If the switch is configured for RSTP and receives a STP (802.1d) BPDU, then STP functionality is assumed.

There is currently no RSTP support in the Linux Kernel and therefore BISDN Linux uses [mstpd](https://github.com/mstpd/mstpd) to configure and manage RSTP.

mstpd is managed by systemd and is disabled by default. For documentation on how to manage systemd services please refer to [systemd getting started](/getting_started/configure_baseboxd.md#getting-started).

## RSTP configuration

When `mstpd` is enabled, any configured bridge will have STP enabled by default. Therefore, it is not required to specify the `stp_state` flag when creating a bridge:

```
ip link add name swbridge type bridge vlan_filtering 1
```


The following steps of configuring the ports and attaching them to the bridge can be seen in [VLAN Bridging](/network_configuration/vlan_bridging.html#vlan-bridging-8021q).

## RSTP operation

After setting up the bridge and its ports, the RSTP state on the bridge can be managed with the `mstpdctl` utility. The following command shows an example command output.

**WARNING**: The `brctl` tool does not work with bridges managed by `mstpd`. Use `mstpctl` instead.
{: .label .label-yellow }

```
agema-ag4610:/home/basebox# mstpctl showbridge
swbridge CIST info
  enabled         yes
  bridge id       2.000.6E:F8:F4:3D:E3:D7
  designated root 2.000.6E:F8:F4:3D:E3:D7
  regional root   2.000.6E:F8:F4:3D:E3:D7
  root port       none
  path cost     0          internal path cost   0
  max age       20         bridge max age       20
  forward delay 15         bridge forward delay 15
  tx hold count 6          max hops             20
  hello time    2          ageing time          300
  force protocol version     rstp
  time since topology change 371
  topology change count      4
  topology change            no
  topology change port       port8
  last topology change port  port7
```

```
agema-ag4610:/home/basebox# mstpctl showport swbridge port7
   port7 8.001 forw 2.000.6E:F8:F4:3D:E3:D7 2.000.6E:F8:F4:3D:E3:D7 8.001 Desg
agema-ag461-:/home/basebox# mstpctl showport swbridge port8
   port8 8.002 forw 2.000.6E:F8:F4:3D:E3:D7 2.000.6E:F8:F4:3D:E3:D7 8.002 Desg
```
