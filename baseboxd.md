---
title: Basebox
nav_order: 3
---

# Baseboxd

Baseboxd is the BISDN SDN controller used for integrating whitebox switches
into Linux.

Based on [OpenFlow Data Path Abstraction (OF-DPA)](http://broadcom-switch.github.io/of-dpa/doc/html/index.html),
it translates Linux netlink into switch rules. Our solution can be easily
managed and flawlessly integrated in any existing Linux environment.

## Architecture Overview

baseboxd communicates northbound with the Linux kernel via netlink and
southbound with the switch using OpenFlow and the OpenFlow Data Path
Abstraction interface (OF-DPA). The Linux network stack is used to directly
represent and modify the state of the switching infrastructure. For each switch
port controlled by baseboxd, a Linux tap interface is created on the baseboxd
host operating system.

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

baseboxd is therefore an agent which listens for changes in the states of:

* The Switch (e.g. OpenFlow port status messages)
* Linux tap interfaces (netlink messages)

On the switch side, it listens for OFPT_PORT_STATUS asynchronous messages, and
updates the states of the tap ports accordingly. It creates tap interfaces for
each port that is up, and deletes them when they go down. This interaction can
be observed on the illustration below.

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

On the kernel side, it listens to netlink events, which are triggered by
changes to the state of the tap interfaces. These changes are then propagated
by baseboxd down to the switch. To give an example, if we enable a VLAN on a
tap interface controlled by baseboxd, baseboxd detects the change and
configures the flow and group tables of the switch pipeline accordingly.

```
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
+------------+
```

## netlink

baseboxd consumes netlink messages produced by the Linux kernel on certain
events on the tap interfaces (e.g. the tap interface is added to a bridge or an
IP address is added to the tap interface). baseboxd then reacts by managing the
corresponding hardware switch ports. baseboxd uses the libnl libraries, which
provide a simple interface for sending and receiving netlink messages.

Since baseboxd responds directly to the relevant netlink messages, the intended
way to interface with baseboxd is using tools such as iproute2,
systemd-networkd or FRR.

## OpenFlow

baseboxd communicates with switches using the OpenFlow protocol. Our
implementation uses the Broadcom OF-DPA flavor specifically, which is based on
[OpenFlow 1.3.4](https://www.opennetworking.org/wp-content/uploads/2014/10/openflow-switch-v1.3.4.pdf).
[OF-DPA 2.0 table type pattern specification](https://github.com/Broadcom-Switch/of-dpa/blob/master/OFDPAS-ETP100-R.pdf)
guidelines are available. Switches compatible with Broadcom’s SDK come with the
OF Agent. OF Agent is a daemon which provides the OpenFlow connection between
the control plane and the Broadcom-implemented data plane. It enforces the
table type pattern specification on the switch side.

```
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
+--------------+  +
```
