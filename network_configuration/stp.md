---
title: Spanning Tree Protocol (STP)
parent: Network Configuration
---

# Spanning Tree Protocol (STP)

## Introduction

The Spanning Tree Protocol (STP) is meant to build loop-less topologies in Layer 2 networks. It works by distributively creating network paths without loops that could be harmful in case of e.g. flooding broadcast messages, by disabling (blocking) ports in the configured bridges. This document shows how to configure the STP implementation available in Linux.

**WARNING**: BISDN Linux currently supports standard STP (IEEE Standard 802.1d) and RSTP (IEEE Standard 802.1w). In most modern network topologies RSTP is used because it provides significantly faster recovery in case of topology changes. To configure RSTP you *have* to use the packaged [mstpd](https://github.com/mstpd/mstpd) instead of the default STP implementation in the Linux kernel.
{: .label .label-red}

**Note**: BISDN Linux ships with [mstpd](https://github.com/mstpd/mstpd) disabled. Every STP enabled bridge will use the kernel implementation of STP, and can be managed using `brctl`. If mstpd is enabled (and running), STP will be enabled and handled by mstpd in user-space on EVERY bridge created.
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

After setting up the bridge and bridge ports, the STP state on the bridge can be managed over the `brctl` utility. A complete reference can be found on the [brctl man page](https://linux.die.net/man/8/brctl).
The following example shows the output of a `brctl` command:

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

# Multiple Spanning Tree Protocol (MSTP)

## Introduction

Multiple Spanning Tree Protocol extends the functionality of classical STP by
the ability to create Multiple Spanning Tree Instances (MSTIs). These spanning
tree instances can be managed independently per VLAN. Each VLAN has to be
managed in exactly one MSTI, while one MSTI may manage multiple VLANs at the
same time. Additionally MSTP defines "Regions" as a group of MSTP enabled
bridges that share the same "Configuration Name" and "Configuration Digest".
Each MSTI is managed individually in each region and all regions are managed
within one Common Internal Spanning Tree (CIST).
MSTP is defined in 802.1s as an extension to 802.1Q. Please refer to the
standard for all the details and the specification of MSTP.
Similar to RSTP, there is currently no MSTP support in the Linux Kernel and
therefore BISDN Linux uses [mstpd](https://github.com/mstpd/mstpd) to configure
and manage it. Since the mstpd.service is disabled by default, it has to be
started and enabled before MSTP can be configured and used.


## MSTP configuration

To enable MSTP on a STP enabled bridge, you need to force the STP version of the
bridge to mstp (instead of "rstp", which would be used by default when mstpd is
managing the bridge). Assuming your bridge is named "swbridge", this can be done
by running:

```
root@accton-as4610:~# mstpctl setforcevers swbridge mstp
root@accton-as4610:~# mstpctl showbridge swbridge
swbridge CIST info
  enabled         yes
  bridge id       8.000.5A:56:E3:62:AF:A7
  designated root 8.000.5A:56:E3:62:AF:A7
  regional root   8.000.5A:56:E3:62:AF:A7
  root port       none
  path cost     0          internal path cost   0
  max age       20         bridge max age       20
  forward delay 15         bridge forward delay 15
  tx hold count 6          max hops             20
  hello time    2          ageing time          300
  force protocol version     mstp
  time since topology change 54
  topology change count      0
  topology change            no
  topology change port       None
  last topology change port  None
```

In the next step, you should create as many individual trees (MSTIs) as you need
to manage the VLANs bridged by each switch. Assuming you bridge `VLAN 2` and
`VLAN 3` and want to manage the spanning trees of those individually, you can
create two trees (MSTIs) named `2` and `3` (the names do not have to match the
VLANs you want to mange in them and can be choosen in the range between 1-65,
while 0 is already created by default to manage all VLANs not mapped to any
other tree).

```
root@accton-as4610:~# mstpctl showmstilist swbridge
swbridge list of known MSTIs:
 0
root@accton-as4610:~# mstpctl createtree swbridge 2
root@accton-as4610:~# mstpctl createtree swbridge 3
root@accton-as4610:~# mstpctl showmstilist swbridge
swbridge list of known MSTIs:
 0 2 3
```

To abstract the mapping between MSTIs and VLANs, each VLAN ID (vid) needs to be
assigned to a filtering id (fid) (the name of the fid does not have to match
the id of the VLAN), which will then in turn each be assigned to an mstid.

Mapping FID to VID (please make sure to put FID and VID in the correct order):

```
Usage: mstpctl setvid2fid <bridge> <FID>:<VIDs List> [<FID>:<VIDs List> ...]
  Set VIDs-to-FIDs allocation
```

```
root@accton-as4610:~# mstpctl showvid2fid swbridge
swbridge VID-to-FID allocation table:
  FID 0: 1-4094
root@accton-as4610:~# mstpctl setvid2fid swbridge 2:2
root@accton-as4610:~# mstpctl setvid2fid swbridge 3:3
root@accton-as4610:~# mstpctl showvid2fid swbridge
swbridge VID-to-FID allocation table:
  FID 0: 1,4-4094
  FID 2: 2
  FID 3: 3
```

Mapping MSTID to FID (please make sure to put MSTID and FID in the correct order):

```
Usage: mstpctl setfid2mstid <bridge> <mstid>:<FIDs List> [<mstid>:<FIDs List> ...]
  Set FIDs-to-MSTIDs allocation
```

```
root@accton-as4610:~# mstpctl showfid2mstid swbridge
swbridge FID-to-MSTID allocation table:
  MSTID 0: 0-4095
root@accton-as4610:~# mstpctl setfid2mstid swbridge 2:2
root@accton-as4610:~# mstpctl setfid2mstid swbridge 3:3
root@accton-as4610:~# mstpctl showfid2mstid swbridge
swbridge FID-to-MSTID allocation table:
  MSTID 0: 0-1,4-4095
  MSTID 2: 2
  MSTID 3: 3
```

If you want to manage multiple switches in one MST region, you have to make sure
that the mst configuration IDs ("Configuration Name" - by default created based on
the MAC of the bridge that is manged), as well as the configuration itself
("Configuration Digest" - digest of the mstp configuration applied on the
bridge) are the same on all switches within that MST region. If you configured
multiple switches with the commands shown above, your configuration might look
similar to this ("Configuration Name" will be different for you):

```
root@accton-as4610-1:~# mstpctl showmstconfid swbridge
swbridge MST Configuration Identifier:
  Format Selector:      0
  Configuration Name:   5A56E362AFA7
  Revision Level:       0
  Configuration Digest: 8A9442199657EA49D1124EA768B5D9A2
```

```
root@accton-as4610-2:~# mstpctl showmstconfid swbridge
swbridge MST Configuration Identifier:
  Format Selector:      0
  Configuration Name:   3B567362AFB1
  Revision Level:       0
  Configuration Digest: 8A9442199657EA49D1124EA768B5D9A2
```

To place both switches in the same MST region, you can set the "Configuration
Names" on all switches to e.g. "12345" by running (where "1" is the "Revision
Level" here):

```
root@accton-as4610-1/2:~# mstpctl showmstconfid swbridge
root@accton-as4610-1/2:~# mstpctl setmstconfid swbridge 1 12345
root@accton-as4610-1/2:~# mstpctl showmstconfid swbridge
swbridge MST Configuration Identifier:
  Format Selector:      0
  Configuration Name:   12345
  Revision Level:       1
  Configuration Digest: 8A9442199657EA49D1124EA768B5D9A2
```

After applying this configuration, each MSTI will be managed individually within
each MST region and all connected MST regions will be managed in one CIST.
