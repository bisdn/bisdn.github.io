---
title: Frequently Asked Questions (FAQ)
nav_order: 19
---
# Frequently Asked Questions (FAQ)

1. Why do i get a latency above 1ms when trying to ping the IP address assigned to a switch port from a directly connected server ?
   - This is the delay incurred by using the OpenFlow interface on-switch. The traffic destined to the controller is encapsulated in the OpenFlow PACKET_IN, destined to the tap interface created by basebxd. This extra encapsulation and transmission over the OpenFlow channel results in a ~1.5ms delay when pinging the switch port. 
