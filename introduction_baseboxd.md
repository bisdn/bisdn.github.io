# baseboxd
## Introduction
baseboxd is a controller daemon integrating whitebox switches into Linux. Based on [OpenFlow Data Path Abstraction (OF-DPA)][rofl], it translates Linux [netlink][libnl_docs] into switch rules and vice versa. Our solution can be easily managed and flawlessly integrated in any existing Linux environment. It can be combined with CAWR for scaling switch capacity.

## Architecture
baseboxd communicates (upwards) with the Linux kernel over [**netlink**][libnl_docs] and (downwards) with the switch using [**OpenFlow**][of]. The Linux network stack is used to directly represent the state of the switching infrastructure. For each active network interface on a switch controlled by baseboxd, a single Linux tap interface exists on the Basebox host operating system.


```text
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
* The Switch (Openflow port state messages)
* Linux tap interfaces (netlink messages)

From the switch side, it listens for OFPT_PORT_STATUS async messages, and updates the states of the tap ports accordingly. It creates tap interfaces for each port that is up, and disables them when they go down *(implementation pending)*. This interaction can be observed on the illustration below.

```text
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

* complete workflow implementation pending *
```

On the kernel side, it listens to netlink events, which are triggered by changes to the state of the tap interfaces. These changes are then propagated by baseboxd down to the switch. To give an example, if we enable a VLAN on a watched tap interface, baseboxd will detect the change and re-configure the switch accordingly through the southbound [OpenFlow][of] interface.

```text
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

### netlink
baseboxd consumes netlink messages produced by the kernel when observed tap interfaces change state. baseboxd then reacts by managing the corresponding hardware switch ports. baseboxd uses the [**libnl**][libnl_docs] libraries, which provide a simple interface for sending and receiving netlink messages.

Since baseboxd responds directly to the relevant netlink messages, it is one of the intended ways to interface with baseboxd. One may use tools such as [iproute2][] and [systemd-networkd][] to configure baseboxd through this interface.


### OpenFlow
baseboxd communicates with switches using the [OpenFlow protocol][of]. Our implementation uses the Broadcom OF-DPA flavour specifically. It abides by the [OF-DPA][ofdpa] table type pattern specification guidelines. Switches compatible with Broadcom's SDK come with the `OF Agent`. `OF Agent` is a daemon which serves the OpenFlow connection between the control plane, and the Broadcom-implemented data plane. It enforces the table type pattern specification on the side of the switch.

```text
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

## Additional resources
* [baseboxd github][baseboxd_gh]
* [etcd github][etcd_gh]
* [iproute2][iproute2]
* [libnl documentation][libnl_docs]
* [OF-DPA 2.0][ofdpa]
* [OpenFlow 1.3 specification][of]
* [Revised OpenFlow Library (ROFL)][rofl]

[ofdpa]: https://github.com/Broadcom-Switch/of-dpa (OF-DPA 2.0 GitHub Repository)
[of]: https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-spec-v1.3.0.pdf (Openflow v1.3 specification pdf)
[etcd_gh]: https://github.com/coreos/etcd (etcd GitHub repository)
[iproute2]: https://wiki.linuxfoundation.org/networking/iproute2 (iproute2 Wiki)
[rofl]: https://www.github.com/bisdn/rofl-common (ROFL GitHub Repository)
[baseboxd_gh]: www.github.com/bisdn/basebox (baseboxd GitHub Repository)
[libnl_docs]: https://www.infradead.org/~tgr/libnl/doc/api/ (libnl API Documentation)
[systemd-networkd]: https://github.com/systemd/systemd (systemd GitHub Repository)
