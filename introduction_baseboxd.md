# Baseboxd
## Introduction
Baseboxd is a controller daemon integrating whitebox
switches into Linux. Based on OpenFlow Data Path
Abstraction (OF-DPA), it translates Linux netlink into
switch rules and vice versa. Our solution can be easily
managed and flawlessly integrated in any existing Linux
environment. It can be combined with CAWR for scaling
switch capacity.

## Architecture

Baseboxd communicates (upwards) with the linux kernel over **netlink** and (downwards) with the switch using **OpenFlow**. The Linux network stack is used to directly represent the state of the switching infrastructure. For each active network interface on a switch controlled by baseboxd, a single Linux tap interface exists on the basebox host operating system.


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

Baseboxd is therefore an agant which, while sitting in the middle, listens for changes in the states of:
* The Switch (Openflow port state messages)
* Linux tap interfaces (netlink messages)

From the switch side, it listens for OFPT_PORT_STATUS async messages, and updates the states of the tap ports accordingly. It crates tap interfaces for each port that is up, and disables them when they go down *(implementation pending)*. This interaction can be observed on the illustration below.

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

On the other side, it listens to netlink events, which are triggered by changes to the state of the tap interfaces. These changes are then propagated by baseboxd down to the switch. To give an example, if we enable a VLAN on a watched tap interface, baseboxd will detect the change and re-configure the switch accordingly through the southbound OpenFlow interface.

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
      | 2. OpenFlow configuration - updates to flowtables/grouptables
      |
+-----v------+   
|   switch   |   
+------------+   

```

### netlink

Baseboxd consumes netlink messages produced by the kernel when observed tap interfaces change state. Baseboxd then reacts to by managing the corresponding hardware switch ports. Baseboxd uses the **libnl** libraries, which provide a simple interface for sending and receivign netlink messages.


### OpenFlow

Baseboxd communicates with switches usint the OpenFlow protocol. Our implementation uses the Broadcom's OF-DPA flavour specifically. It abides by the OF-DPA table type pattern specification guidelines. Switches compatible with Broadcom's SDK come with the `OF Agent`. `OF Agent` is a daemon which serves the OpenFlow connection between the control plane, and the Broadcom-implemented data plane. It enforces the table type pattern specification on the side of the switch.

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

## Additional Resources
1. [OF-DPA 2.0](https://github.com/Broadcom-Switch/of-dpa)
2. [OpenFlow 1.3 specification](https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-spec-v1.3.0.pdf)
3. [etcd github](https://github.com/coreos/etcd)
4. [iproute2](https://wiki.linuxfoundation.org/networking/iproute2)
5. [Revised OpenFlow Library (ROFL)](https://www.github.com/bisdn/rofl-common)
6. [baseboxd github](www.github.com/bisdn/basebox)
7. [libnl documentation](https://www.infradead.org/~tgr/libnl/doc/api/)
