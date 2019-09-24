.. _intro_baseboxd:

########
baseboxd
########

Basebox is the BISDN controller package for data center networks with the following elements:
        * The BISDN Linux Distribution is a Yocto-based operating system for selected whitebox switches
        * baseboxd is a controller daemon integrating whitebox switches into Linux

Introduction
************

baseboxd is a controller daemon integrating whitebox switches into Linux. Based on [OpenFlow Data Path Abstraction (OF-DPA)][rofl], it translates Linux [netlink][libnl_docs] into switch rules and vice versa. Our solution can be easily managed and flawlessly integrated in any existing Linux environment.

Architecture
************
baseboxd communicates (upwards) with the Linux kernel over [netlink][libnl_docs] and (downwards) with the switch using [OpenFlow][of]. The Linux network stack is used to directly represent the state of the switching infrastructure. For each active network interface on a switch controlled by baseboxd, a single Linux tap interface exists on the Basebox host operating system.

.. code-block:: bash

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

baseboxd is therefore an agent which, while sitting in the middle, listens for changes in the states of:
  * The Switch (OpenFlow port state messages)
  * Linux tap interfaces (netlink messages)

On the switch side, it listens for OFPT_PORT_STATUS async messages, and updates the states of the tap ports accordingly. It creates tap interfaces for each port that is up, and deletes them when they go down. This interaction can be observed on the illustration below.

.. code-block:: bash

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

On the kernel side, it listens to netlink events, which are triggered by changes to the state of the tap interfaces. These changes are then propagated by baseboxd down to the switch. To give an example, if we enable a VLAN on a watched tap interface, baseboxd will detect the change and re-configure the switch accordingly through the southbound [OpenFlow][of] interface.
  
  .. _code-block:: bash
  
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
  
netlink
*******

baseboxd consumes netlink messages produced by the kernel when observed tap interfaces change state. baseboxd then reacts by managing the corresponding hardware switch ports. baseboxd uses the [libnl][libnl_docs] libraries, which provide a simple interface for sending and receiving netlink messages.

Since baseboxd responds directly to the relevant netlink messages, it is one of the intended ways to interface with baseboxd. One may use tools such as [iproute2][] and [systemd-networkd][] to configure baseboxd through this interface.


OpenFlow
********

baseboxd communicates with switches using the [OpenFlow protocol][of]. Our implementation uses the Broadcom OF-DPA flavour specifically. It abides by the [OF-DPA][ofdpa] table type pattern specification guidelines. Switches compatible with Broadcom's SDK come with the `OF Agent`. `OF Agent` is a daemon which serves the OpenFlow connection between the control plane, and the Broadcom-implemented data plane. It enforces the table type pattern specification on the side of the switch.

.. _code-block:: bash

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
  
Features
********

baseboxd maps the ports on a switch in a Linux environment. These switch ports can then be configured using the same tools as the ones used to configure Linux interfaces. 
Currently supported features are:
  * Setting interfaces up/down
  * Adding interfaces to bridges
  * Configuring VLANs on interfaces
  * Configuring IP addresses on interfaces
