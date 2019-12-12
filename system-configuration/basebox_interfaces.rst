.. _interfaces:

Interfaces
----------

BISDN Linux maps the physical ports on the switch with an abstract representation via `tuntap <https://www.kernel.org/doc/Documentation/networking/tuntap.txt>`_ interfaces. These interfaces are special Linux software only devices, that are bound to a userspace program, specifically baseboxd for the case in BISDN Linux. 

If the initial configuration in :ref:`baseboxd_setup` is followed correctly, then the following output is expected.

.. code-block:: bash

  $ ip link show
  ...
  8: port1: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000                                                                                                                                   
      link/ether 3e:25:b2:29:0e:40 brd ff:ff:ff:ff:ff:ff
  9: port2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 82:21:77:4b:1c:69 brd ff:ff:ff:ff:ff:ff
    ...


These interfaces can be managed via the :ref:`iproute2` utility, or any netlink supported Linux networking utility. The link state for these interfaces maps to the physical port state. Due to a limitation in the Linux kernel, the interfaces state show up as `UNKNOWN` or `DOWN`, where `UNKNOWN` means that the physical interface has a cable attached.

To prevent ssh access from dataplane ports, the switch has an `iptables <https://linux.die.net/man/8/iptables>`_ rule to block traffic destined to TCP port 22, the default ssh port, on all interfaces except for the management interface. The management interface follows the Predictable Interface naming convention in Linux, and is usually `enp*`.

.. code-block:: bash
  
  :INPUT ACCEPT [176:40142]
  :FORWARD ACCEPT [0:0]
  :OUTPUT ACCEPT [150:38898]
  -A INPUT ! -i enp+ -p tcp -m tcp --dport 22 -j DROP
  COMMIT

The default path for iptables configuration is `/etc/iptables/iptables.rules` for IPv4 and `/etc/iptables/ip6tables.rules` for IPv6 traffic.


