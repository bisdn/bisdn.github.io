---
title: BISDN Linux
nav_order: 1
---

# BISDN Linux

BISDN Linux Distribution is a custom Linux-based operating system for selected
whitebox switches. This lightweight distribution provides a standard Linux
environment and includes FRR, as well as most native Linux networking tools out
of the box.

BISDN Linux exposes the switch's ports as Linux network interfaces so that no
specialized programs are needed for network configuration. Each port is its own
network interface, so you can think of your switch as a Linux server with a lot
of network cards.

## Specifications

* Based on Linux [yocto](https://www.yoctoproject.org/software-overview/downloads/)
  operating system
* Software built on [OF-DPA 3.0](https://github.com/Broadcom-Switch/of-dpa)
* Deployable via [Open Network Install Environment (ONIE)](https://opencomputeproject.github.io/onie/)
* Using [of-agent](https://github.com/Broadcom-Switch/of-dpa/tree/master/src/ofagent)
  as the [OpenFlow](https://www.opennetworking.org/wp-content/uploads/2014/10/openflow-switch-v1.3.5.pdf)
  interface

The following video provides a short overview how BISDN Linux works behind the
scenes:

<iframe width="480" height="360"
src="https://www.youtube.com/embed/K3RUNxrvb8k" frameborder="0"> </iframe>
