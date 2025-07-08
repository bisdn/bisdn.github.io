---
title: Basic Networking
parent: Getting Started
nav_order: 5
---

# Getting started with network configuration

In contrast to many specialized switch operating systems, BISDN Linux does not
provide a specialized CLI for network configuration.

For run time network configuration you can use standard Linux command line
tools. All our examples use the [iproute2](https://linux.die.net/man/8/ip)
utilities, as they provide the most comprehensive options for network
configuration.

To configure persistent network configuration BISDN Linux provides
[systemd-networkd](https://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).
Systemd-networkd allows a variety of options for configuring static network
configuration.

To prevent ssh access from dataplane ports, the switch has an
[iptables](https://linux.die.net/man/8/iptables) rule to block traffic destined
to the default ssh port (TCP port 22) on all interfaces, except for the
management interface. The management interface follows the Predictable
Interface naming convention in Linux, and is usually enp\*.

```
:INPUT ACCEPT [176:40142]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [150:38898]
-A INPUT ! -i enp+ -p tcp -m tcp --dport 22 -j DROP
COMMIT
```

The default path for iptables configuration is ``/etc/iptables/iptables.rules``
for IPv4 and ``/etc/iptables/ip6tables.rules`` for IPv6 traffic.

## Port interfaces

BISDN Linux exposes the physical ports on the switch as individual network
interfaces, named port1, port2 and so on.

```
$ ip link show
...
8: port1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether ea:db:2b:c1:f6:06 brd ff:ff:ff:ff:ff:ff
9: port2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 96:98:0a:8c:0d:a2 brd ff:ff:ff:ff:ff:ff
  ...
```

By default all ports are in a disabled and unconfigured state.

Like any other network interface these can be managed via the
[iproute2](https://linux.die.net/man/8/ip) utility, or any netlink supported
Linux networking utility.

For example, to set ports up, you can do

```
$ sudo ip link set port1 up
$ sudo ip link set port2 up
````

In our example, we have a device connected to port1, but not to port2. We can
now see that both ports are enabled, and port1 has a link:

````
$ ip link show
...
8: port1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether ea:db:2b:c1:f6:06 brd ff:ff:ff:ff:ff:ff
9: port2: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
    link/ether 96:98:0a:8c:0d:a2 brd ff:ff:ff:ff:ff:ff
  ...
```

We can check the physical link configuration (e.g. link speed) using ethtool:

```
$ ethtool port1
Settings for port1:
        Supported ports: [ ]
        Supported link modes:   Not reported
        Supported pause frame use: No
        Supports auto-negotiation: No
        Supported FEC modes: Not reported
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        Advertised FEC modes: Not reported
        Speed: 25000Mb/s
        Duplex: Full
        Port: Twisted Pair
        PHYAD: 0
        Transceiver: internal
        Auto-negotiation: off
        MDI-X: Unknown
```

**WARNING**: All link configurations shown in ethtool are currently read-only
and cannot be modified (meaning any changes done with ethtool will not be
forwarded to the physical link, but just be shown on the port interfaces without
having any effect on the ASIC). Configuring the link speed as in [Disable
auto-negotiation](../platform_configuration/auto_negotiation.md#disable-auto-negotiation)
however, will update the ethtool reported speed.

## Loopback interface

The loopback interface `lo` is a special type of device destined to allow the
switch to communicate with itself. It is not associated with any physical
device and is used to provide connectivity inside the same switch.

There are two IP addresses associated by default with this interface:
`127.0.0.1/8` for IPv4 and `::1/128` for IPv6 networks.

It is possible to configure the loopback interface with other IPv4 and IPv6
addresses, thus providing connectivity to the loopback interface itself. In
order to reach this interface, a "via" route must be present.

## Management interface

BISDN Linux uses `systemd-networkd` to configure the management network
interface. To allow users to ssh to and configure the switch without any
further configuration after installing an image, our yocto build chain adds a
default configuration file to `/lib/systemd/network/80-wired.network` (shown
below), which configures all interfaces named "eth*" or "en*" to use DHCP. By
using this configuration, the management network interface of all switch
platforms automatically uses DHCP for its own address configuration. All other
switch ports are unaffected by this configuration, since they are all named
like `portX` and therefore not matched. To override this configuration file,
you can add a custom file in the `/etc/systemd/network` directory, with a
prefix number lower than `80`. The lower prefix will make sure this file is
read first when starting systemd-networkd (only the first `Match` for each
interface is applied). Please see the [systemd-networkd
docs](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
for more information.

`/lib/systemd/network/80-wired.network`

```
[Match]
Name=en* eth*
KernelCommandLine=!nfsroot
KernelCommandLine=!ip

[Network]
DHCP=yes

[DHCP]
RouteMetric=10
ClientIdentifier=mac
```

# Network configuration with iproute2

To configure an interface on the switch, you have to configure the
corresponding port interface created by baseboxd. If, for example, you have
connected "port1" of the switch to "eno2" of your server and want to test a
simple ping between these two, you can assign IP addresses to both interfaces
in a very similar way:

On the switch:

```
root@agema-ag7648: ip address add 192.168.0.1/24 dev port1
```

On the server:

```
root@myserver: ip address add 192.168.0.2/24 dev eno2
```

You should now be able to ping the IP address configured on "port1" on your
switch from your server:

On the server:

```
root@myserver: ping 192.168.0.1
```

To configure more complex scenarios, please refer to the [Network
Configuration](../network_configuration.md) section.

# Persisting network configuration with systemd-networkd

Multiple ways of storing network configuration exist on Linux systems. BISDN
Linux supports
[systemd-networkd](https://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html)
for single Basebox setups.

systemd-networkd uses .network files to store network configuration. For
details please see the [systemd-networkd
manual](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
The .network files (in directory /etc/systemd/network/) are processed in
lexical order and only the first file that matches is applied.

In the example below, the file 20-port50.network is processed first, meaning
that port50 will get a dedicated configuration while all other ports get the
generic one.
That also means port50 is not getting the configuration for LLDP, but all other
ports do (as these are configured using file 30-port.network)

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
