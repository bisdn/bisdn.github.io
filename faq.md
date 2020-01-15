---
title: Frequently Asked Questions (FAQ)
nav_order: 19
---
# Frequently Asked Questions (FAQ)

1. Why do i get a latency above 1ms when trying to ping the IP address assigned to a switch port from a directly connected server ?
   - This is the delay incurred by using the OpenFlow interface on-switch. The traffic destined to the controller is encapsulated in the OpenFlow PACKET_IN, destined to the tap interface created by basebxd. This extra encapsulation and transmission over the OpenFlow channel results in a ~1.5ms delay when pinging the switch port. 

2. Why would I prefer BISDN Linux?
  - Linux kernel version flexibility. The Linux kernel netdev is a fast changing environment with new features being added often. By creating our own Linux distribution, we have control over the features that get added to our networking devices, and make sure that these features are stable, tested and production ready. 
  - The buildchain for BISDN Linux is based on the yocto project. yocto allows a layered structure of recipes, so we can reuse recipes for various platforms.
  - Being able to use modern concepts like systemd in versions that are more stable than those of standard distributions. (in general: use newer upstream versions of Open Source projects)
