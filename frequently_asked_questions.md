---
title: Frequently Asked Questions (FAQ)
nav_order: 9
---
# Frequently Asked Questions (FAQ)

1. Why do i get a latency above 1 ms when trying to ping the IP address assigned to a switch port from a directly connected server ?
- This is the delay incurred by using the OpenFlow interface on-switch. The traffic destined to the controller is encapsulated in the OpenFlow PACKET_IN, destined to the tap interface created by baseboxd. This extra encapsulation and transmission over the OpenFlow channel results in a ~1.5 ms delay when pinging the switch port.

2. Why do some packets with TTL=1 not reach my router?
- Switches that forward packets may have a rule in the "Unicast Routing" table to route the packets to the CPU. In `eBGP` the packets carrying BGP messages have a TTL=1, which results in the packets being dropped when they would reach the CPU. For this reason there exists a switch control `L3UcastTtl1ToCpu` to enable routing TTL=1 packets to the CPU. For more information refer to [SwitchControl section](platform_configuration/switchcontrol.md#ttl-controls).
