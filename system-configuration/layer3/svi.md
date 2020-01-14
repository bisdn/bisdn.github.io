---
date: '2020-01-07T16:07:30.187Z'
docname: system-configuration/svi
images: {}
path: /system-configuration-svi
title: Switch VLAN Interface
parent: Layer 3
nav_order: 1
---

# Switch VLAN Interface

## Introduction

Extending the layer 2 domain to a layer 3 routed network can be done via the Switch VLAN Interfaces (SVI). These interfaces allow for routing inter-VLAN traffic, removing the need for an external router. Attaching these interfaces to the bridge will provide as well a gateway for a certain VLAN. There is a 1:1 mapping between a VLAN and a SVI. Creating these interfaces is done with the following commands, after creation and port attachment to the bridge.

## iproute2

**WARNING**: Despite Linux providing multiple alternatives for network configuration, iproute2 is the preferred configuration tool for BISDN Linux. The use of other tools, like ifconfig is not supported.
{: .label .label-red }

```
# add a link to the previously created bridge with the same VLAN as PORTX
ip link add link ${BRIDGE} name ${BRIDGE}.${BR_VLAN} type vlan id ${BR_VLAN}

# allow traffic with the VLAN used on PORTX on the bridge
bridge vlan add vid ${BR_VLAN} dev ${BRIDGE} self

# set previously created link on bridge up
ip link set ${BRIDGE}.${BR_VLAN} up
```

The IP address for this interface can then be set with.

```
ip address add ${SVI_IP} dev ${BRIDGE}.${BR_VLAN}
```

## systemd-networkd

The corresponding systemd-networkd configuration adds the [Network] section on the swbridge.network file:

```
10-swbridge.network:

[Match]
Name=swbridge

[BridgeVLAN]
VLAN=10
VLAN=20

[Network]
VLAN=swbridge.10
```

The interface swbridge.10 also has a .netdev and .network pair of files.

```
20-swbridge10.netdev:

[NetDev]
Name=swbridge.10
Kind=vlan

[VLAN]
Id=10

20-swbridge10.network:

[Match]
Name=swbridge.10

[Network]
Address=10.0.10.1/24
```


