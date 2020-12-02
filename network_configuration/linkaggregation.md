---
title: Link Aggregation
parent: Network Configuration
---

# Link Aggregation 

## Introduction

Link Aggregation, or bonding, is a feature that allows to aggregate several network interfaces into a single virtual interface, known as a bond. Bonding interfaces together allows for channel redundancy, in case of link failure for example; or to aggregate bandwidth.

BISDN Linux bonds can work in one of the following modes:
 - Round Robin (bond mode 0) which sequentially transmits packets on the available interfaces.
 - Active Backup (bond mode 1) where only one slave of the bond is active.
 - 802.3AD LACP (bond mode 4) referring to dynamic link aggregation.

For further explanation of bond modes refer to [bonding documentation](https://wiki.linuxfoundation.org/networking/bonding)

## iproute2

Creation of the bond interface is done with the following commands:

```
ip link add bond1 type bond mode $bond_mode
ip link set bond1 up
```

Attaching a slave interface to the bond is done via:

```
ip link set $PORT master bond1 
ip link set $PORT up
```

After creating and setting up the bonded interface, it can be used as the normal BISDN Linux switch ports. For example adding an IP address is done via:

```
ip address add 10.0.0.2/24 dev bond1
```

A bond can also be a bridge slave interface.

```
ip link set bond1 master $BRIDGE
```

## systemd-networkd

A `.netdev` file for the bond needs to be created in `/etc/systemd/network/`, containing the device type (bond) and its configurations. 

```
10-bond1.netdev

[NetDev]
Name=bond1
Kind=bond

[Bond]
Mode=active-backup
MIIMonitorSec=0.1
```

The slave tap interface is configured via

```
20-port2.network
[Match]
Name=port2

[Network]
Bond=bond1
PrimarySlave=true
```

For reference to the parameters used to configured the bonds and the tap interfaces, refer to [.netdev file documentation](https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#%5BBond%5D%20Section%20Options) and [.network file documentation](https://www.freedesktop.org/software/systemd/man/systemd.network.html#Bond=).
