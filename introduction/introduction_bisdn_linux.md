.. _bisdn_linux_intro:

###########
BISDN Linux
###########

Introduction
************

BISDN Linux Distribution is a custom Linux-based operating
system for selected whitebox switches. This lightweight
distribution supports baseboxd, FRR, as well as most native
Linux networking tools.

Specifications
**************

  * Based on Linux [yocto 2.5 (sumo)][yocto] operating system
  * Software built on [OF-DPA 3.0][ofdpa]
  * Deployable via [Open Network Install Environment (ONIE)][onie]
  * Using [of-agent][ofa] as the [OpenFlow][of] interface
  * SSH (port 22) is denied on all data plane ports by default using [iptables][iptables]
  
Compatibility
*************

The BISDN Linux Distribution is available for the following whitebox switch platforms:
  * AGEMA AG5648
  * AGEMA AG7648
  * AGEMA AG8032
  * AGEMA AG9032
  * Celestica Redstone XP
  * Edge-core AS5712-54X
  * QuantaMesh-BMS-T3048-LY8

Download links to the latest BISDN linux switch images can always be found on [repo.bisdn.de/pub/onie][image-repo]
