---
title: VLAN Bridging QinQ (802.1ad)
parent: Network Configuration
---

# VLAN Bridging QinQ (802.1ad)

## Introduction

QinQ VLANs, or 802.1ad is an extension to the VLAN standard that allows multiple VLAN tags to be attached to a single frame. Using stacked VLANs, providers are able to bundle traffic tagged with different VLAN into a single Service tag.

Similarly to 802.1q bridging, it is possible to configure 802.1ad VLANs using [iproute2](#iproute2) or [systemd-networkd](#systemd-networkd).

**WARNING**: Any bridge configured to forward VLAN traffic with either protocol 802.1q or 802.1ad will only forward traffic of the selected VLAN protocol type.
{: .label .label-red }

**WARNING**: Stacking VLANs and switching based on both tags is currently not supported. See [stacked VLAN support](#stacked-vlan-support) for current behavior and limitations.
{: .label .label-red }

## iproute2

Creation of the 802.1ad bridge is done with the following commands.

```
BRIDGE=${BRIDGE:-swbridge}
...
ip link add name ${BRIDGE} type bridge vlan_filtering 1 vlan_default_pvid 1 vlan_protocol 802.1ad
ip link set ${BRIDGE} up
```

The rest of the configuration follows the same steps as the [802.1q bridging](/network_configuration/vlan_bridging.html#iproute2) section.

## systemd-networkd

A `.netdev` file for the bridge needs to be created in `/etc/systemd/network/`, containing the device type (bridge) and its configurations. Specifically related to 802.1ad, we configure the bridge VLAN protocol with the `VLANProtocol` attribute:

```
10-swbridge.netdev

[NetDev]
Name=swbridge
Kind=bridge

[Bridge]
DefaultPVID=0
VLANFiltering=1
VLANProtocol=802.1ad
```

The remaining configurations follow the same steps from the instructions in the [802.1q bridging](/network_configuration/vlan_bridging.html#systemd-networkd) section.

## stacked VLAN support

Support for configuring stacked VLANs in any way is currently not implemented. The switch will still forward double tagged packets according to their outer VLAN tag, as long as the outer VLAN tag's protoctol matches the configured VLAN protocol of the bridge.

The following limitations apply:

* Learning is done based on the outer VLAN tag, so all inner VLANs share one learning database.
* PVID port configuration only works for untagged packets. Single tagged packets with an unexpected VLAN protocol will not be converted to double tagged and will be dropped instead.
* Adding VLAN interfaces of ports as bridge members is not supported and will not add or remove any additional VLAN tags on that port.
