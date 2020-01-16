---
title: Interfaces
parent: Layer 1
---

# Interfaces

BISDN Linux maps the physical ports on the switch with an abstract representation via [tuntap](https://www.kernel.org/doc/Documentation/networking/tuntap.txt) interfaces. These interfaces are special Linux software only devices, that are bound to a userspace program, specifically baseboxd for the case in BISDN Linux.

If the [System configuration](.setup/setup_standalone.html#system-configuration) setup for baseboxd is followed correctly, then the following output is expected.

```
$ ip link show
...
8: port1: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
    link/ether 3e:25:b2:29:0e:40 brd ff:ff:ff:ff:ff:ff
9: port2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 1000
  link/ether 82:21:77:4b:1c:69 brd ff:ff:ff:ff:ff:ff
  ...
```

These interfaces can be managed via the [iproute2](https://linux.die.net/man/8/ip) utilities, or any netlink supported Linux networking utility. The link state for these interfaces maps to the physical port state. Due to a limitation in the Linux kernel, the interfaces state show up as UNKNOWN or DOWN, where UNKNOWN means that the physical interface has a cable attached.

**WARNING**: Despite Linux providing multiple alternatives for network configuration, iproute2 is the preferred configuration tool for BISDN Linux. The usage of other network configuration tools (e.g. ifconfig) is not covered in our documentation and might lead to unintended results.
{: .label .label-red }

To prevent ssh access from dataplane ports, the switch has an [iptables](https://linux.die.net/man/8/iptables) rule to block traffic destined to the default ssh port(TCP port 22) on all interfaces, except for the management interface. The management interface follows the Predictable Interface naming convention in Linux, and is usually enp\*.

```
:INPUT ACCEPT [176:40142]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [150:38898]
-A INPUT ! -i enp+ -p tcp -m tcp --dport 22 -j DROP
COMMIT
```

The default path for iptables configuration is ``/etc/iptables/iptables.rules`` for IPv4 and ``/etc/iptables/ip6tables.rules`` for IPv6 traffic.

# Loopback interface

The loopback interface `lo` is a special type of device destined to allow the switch to communicate with itself. It is not associated with any physical device and is used to provide connectivity inside the same switch.

There are two IP addresses associated by default with this interface: `127.0.0.1/8` for IPv4 and `::1/128` for IPv6 networks.

It is possible to configure the loopback interface with other IPv4 and IPv6 addresses, thus providing connectivity to the loopback interface itself. In order to reach this interface, a "via" route must be present.
