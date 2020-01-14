---
images: {}
title: IPv4 static routing
parent: Layer 3
nav_order: 3
---

# IPv4 static routing

## Introduction

As a L3-enabled SDN controller, baseboxd can be configured for routing purposes. Examples in this part are added to show how IP addresses (IPv4 and IPv6) and routes can be attached to certain interfaces. Managing static routes is done typically via iproute2 and systemd-networkd, and the following sections will describe this in more detail. For dynamic routing, BISDN adopted FRRouting, to support routing protocols such as BGP and OSPF. Further information can be seen in section FRRouting.

**WARNING**: Configuring a Linux box to work as a router assumes that sysctl net.ipv4.conf.all.forwarding=1. BISDN Linux has this sysctl already enabled by default, but routing issues should be debugged first by checking the value for this configuration.
{: .label .label-red }

## iproute2

Adding an IP address to a baseboxd interface is done simply by

```
ip link set ${PORT} up
ip address add ${IPADDRESS} dev ${PORT}
```

Configuring a static route on the interface via ip route:

```
ip route add ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}
```

Route and IP address deletion is done via

```
ip address del ${IPADDRESS} dev ${PORT}
ip route del ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}
```

## systemd-networkd

IPv4 routing in systemd-networkd is done using the [Network] and [Route] sections to the port .network file. In the [Route] section, the Gateway= section *must* be present in the case when DHCP is not used.

```
10-port1.network:

[Match]
Name=${PORT}

[Network]
Address=${IPADDRESS}

[Route]
Gateway=${GATEWAY}
Destination=${DESTINATION_NETWORK}/${DESTINATION_MASK}
```


