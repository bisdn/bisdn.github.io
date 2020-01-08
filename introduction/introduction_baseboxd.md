---
date: '2020-01-07T16:07:30.187Z'
docname: introduction/introduction_baseboxd
images: {}
path: /introduction-introduction-baseboxd
title: Baseboxd introduction
nav_order: 3
---

# Baseboxd introduction

Basebox is the BISDN controller package for data center networks with the following elements:

    
    * The BISDN Linux Distribution is a Yocto-based operating system for selected whitebox switches


    * baseboxd is a controller daemon integrating whitebox switches into Linux

Based on OpenFlow Data Path Abstraction, it translates Linux netlink into switch rules. Our solution can be easily managed and flawlessly integrated in any existing Linux environment.

## Architecture

baseboxd communicates (upwards) with the Linux kernel over netlink and (downwards) with the switch using OFDPA. The Linux network stack is used to directly represent the state of the switching infrastructure. For each network interface on a switch controlled by baseboxd, a single Linux tap interface exists on the Basebox host operating system.

```
+------------+   +
|   kernel   |   |
+-----^------+   |
      |          |
      | netlink  | control plane
      |          |
+-----v------+   |
|  baseboxd  |   |
+-----^------+   +
      |
      | OpenFlow
      |
+-----v------+   +
|   switch   |   | data plane
+------------+   +
```

baseboxd is therefore an agent which, while sitting in the middle, listens for changes in the states of:

    
    * The Switch (OpenFlow port state messages)


    * Linux tap interfaces (netlink messages)

On the switch side, it listens for OFPT_PORT_STATUS asynchronous messages, and updates the states of the tap ports accordingly. It creates tap interfaces for each port that is up, and deletes them when they go down. This interaction can be observed on the illustration below.

```
+------------+
|   kernel   |
+-----^------+
      |
      | 2. call rtnl_link_set_carrier(struct rtnl_link *link, uint8_t status)
      | /libnl function call/
+------------+
|  baseboxd  |
+-----^------+
      |
      | 1. send OFPT_PORT_STATUS
      | /OpenFlow/
+------------+
|   switch   |
+------------+
```

On the kernel side, it listens to netlink events, which are triggered by changes to the state of the tap interfaces. These changes are then propagated by baseboxd down to the switch. To give an example, if we enable a VLAN on a watched tap interface, baseboxd will detect the change and re-configure the switch accordingly through the southbound OpenFlow Data Path Abstraction interface.

<!-- _code-block:: bash

+------------+
|   kernel   |
+------------+
      |
      | 1. netlink event - VLAN added
      |
+-----v------+
|  baseboxd  |
+------------+
      |
      | 2. OpenFlow configuration - updates to flow tables/group tables
      |
+-----v------+
|   switch   |
+------------+ -->
## netlink

baseboxd consumes netlink messages produced by the kernel when observed tap interfaces change state. baseboxd then reacts by managing the corresponding hardware switch ports. baseboxd uses the libnl libraries, which provide a simple interface for sending and receiving netlink messages.

Since baseboxd responds directly to the relevant netlink messages, it is one of the intended ways to interface with baseboxd. One may use tools such as iproute2 and systemd-networkd to configure baseboxd through this interface.

## OpenFlow

baseboxd communicates with switches using OpenFlow. Our implementation uses the Broadcom OF-DPA flavor specifically. It abides by the OFDPA table type pattern specification guidelines. Switches compatible with Broadcom’s SDK come with the OF Agent. OF Agent is a daemon which serves the OpenFlow connection between the control plane, and the Broadcom-implemented data plane. It enforces the table type pattern specification on the side of the switch.

<!-- _code-block:: bash

+--------------+  +
|   baseboxd   |  | controller
+------^-------+  +
       |
       |
+------v-------+  +
|   OF Agent   |  |
+------^-------+  |
       |          |
       |          |
+------v-------+  |
|    OF-DPA    |  |
+------^-------+  |
       |          | switch
       |          |
+------v-------+  |
| Broadcom SDK |  |
+------^-------+  |
       |          |
       |          |
+------v-------+  |
|     ASIC     |  |
+--------------+  + -->
