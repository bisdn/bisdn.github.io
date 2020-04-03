---
title: VLAN Bridging QinQ (802.1ad)
parent: Network Configuration
---

# VLAN Bridging QinQ (802.1ad)

## Introduction

QinQ VLANs, or 802.1ad is an extension to the VLAN standard that allows multiple VLAN tags to be attached to a single frame. Using stacked VLANs, providers are able to bundle traffic tagged with different VLAN into a single Service tag.

**WARNING**: Any bridge configured to forward VLAN traffic with either protocol 802.1Q or 802.1ad will only forward traffic of the selected VLAN protocol type.
{: .label .label-red }

## iproute2

Creation of the 802.1ad bridge is done with the following commands.

```
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1 vlan_protocol 802.1ad
ip link set ${BRIDGE} up
```

The rest of the configuration follows the same steps as the Bridging section.

