---
title: Basic Networking
parent: Getting Started
nav_order: 5
---

# Getting started with network configuration

Before starting with actually configuring the switch interfaces, you should first familiarise yourself with how interfaces are created and how they fit into the BISDN Linux architecture.

## Interfaces

BISDN Linux maps the physical ports on the switch with an abstract representation via [tuntap](https://www.kernel.org/doc/Documentation/networking/tuntap.txt) interfaces. These interfaces are special Linux software only devices, that are bound to a userspace program, specifically baseboxd for the case in BISDN Linux.

If you followed the instructions from [Configure Baseboxd](configure_baseboxd.md), you should now be able to display all ports.

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

The tap interfaces have their link speed and duplex settings reported via ethtool, visible via

```
$ ethtool port1
Settings for port1:
        ....
        Speed: 25000Mb/s
        Duplex: Full
```

**WARNING**: The link speed setting is currently only read-only via ethtool. Configuring the link speed as in [Disable auto-negotiation](.setup/setup_standalone.html#disable-auto-negotiation) updates the ethtool reported speed and duplex settings.


## Loopback interface

The loopback interface `lo` is a special type of device destined to allow the switch to communicate with itself. It is not associated with any physical device and is used to provide connectivity inside the same switch.

There are two IP addresses associated by default with this interface: `127.0.0.1/8` for IPv4 and `::1/128` for IPv6 networks.

It is possible to configure the loopback interface with other IPv4 and IPv6 addresses, thus providing connectivity to the loopback interface itself. In order to reach this interface, a "via" route must be present.

# Network configuration with iproute2

To configure an interface on the switch, you have to configure the corresponding port (tap interface) created by baseboxd. If for example you have connected "port1" of the switch to "eno2" of your server and want to test a simple ping between these two, you can assign IP addresses to both interfaces in a very similar way:

On the switch:
```
root@agema-ag7648: ip address add 192.168.0.1/24 dev port1
```

On the server:
```
root@myserver: ip address add 192.168.0.2/24 dev eno2
```

You should now be able to ping the IP address configured on "port1" on your switch from your server:

On the server:
```
root@myserver: ping 192.168.0.1
```

To configure more complex scenarios, please refer to the [Network Configuration](../network_configuration.md) section.


# Persisting network configuration with systemd-networkd

Multiple ways of storing network configuration exist on Linux systems. BISDN Linux supports [systemd-networkd](https://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html) for single Basebox setups.

systemd-networkd uses .network files to store network configuration. For details please see the [systemd-networkd manual](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
The .network files (in directory /etc/systemd/network/) are processed in lexical order and only the first file that matches is applied.

In the example below, the file 20-port50.network is processed first, meaning that port50 will get a dedicated configuration while all other ports get the generic one.
That also means port50 is not getting the configuration for LLDP, but all other ports do (as these are configured using file 30-port.network)

```
root@agema-ag7648:/etc/systemd/network# cat 20-port50.network
[Match]
Name=port50

[Network]
Address=10.20.30.20/24

root@agema-ag7648:/etc/systemd/network# cat 30-port.network
[Match]
Name=port*

[Network]
LLDP=yes
EmitLLDP=yes
LLMNR=no
```
