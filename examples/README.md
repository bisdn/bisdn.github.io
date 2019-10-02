.. _examples:

Overview
========

This chapter serves the purpose of adding baseboxd's example configurations. These examples are also available on 
'baseboxd github page <https://github.com/bisdn/basebox/tree/master/examples>'_ as scripts to be run on the Basebox controller.

Physical Topology
=================

These examples are designed to be used with a single switch/ controller and a single physical server. Namespaces are used on the servers to improve the flexibility of the examples by emulating two (or more) physical hosts.

Bridging
--------

These examples describe the process of adding a VLAN-aware bridge interface to the Linux environment, and attaching ports to this bridge.

Network bridges allow to create multiple network segments, forwarding packets based on Ethernet addresses. This mechanism creates then a Layer 2 domain across the configured interfaces on the bridge. 

.. warning:: baseboxd supports only the VLAN-Aware bridge mode. Creating traditional bridges will result in undefined behaviour.

The 'bridging example script <https://github.com/bisdn/basebox/blob/master/examples/bridging/01-controller>'_ will create the following setup on the controller.

.. code-block:: bash

      +--------------+
      |   swbridge   |
      ++------------++
       |            |
  +----+--+       +--+----+
  | port1 |       | port2 |
  +-------+       +-------+

Bridge creation is done with the following command.

.. code-block:: bash
  
  BRIDGE=${BRIDGE:-swbridge}
  ...
  ip link add name ${BRIDGE} type bridge vlan_filtering 1
  ip link set ${BRIDGE} up

The `vlan_filtering 1` flag sets the VLAN-aware bridge mode. The traditional bridging mode in Linux, created without this `vlan_filtering` flag, accepts only one VLAN per bridge, and the ports attached must have VLAN-subinterfaces configured. For a large number of VLANS, this poses an issue with scalability, which is the motivation for the usage of VLAN-aware bridges, where each bridge port will be configured with a list of allowed VLANS. 

Another relevant flag for the creation of VLAN-aware bridges is the `vlan_default_pvid`, setting the default PVID for the bridge. 

Attaching baseboxd's interfaces to the created `swbridge` is done with:

.. code-block:: bash

  # port A
  ip link set ${PORTA} master ${BRIDGE}
  ip link set ${PORTA} up

  # port 2
  ip link set ${PORTB} master ${BRIDGE}
  ip link set ${PORTB} up

Finally, configuring the VLANs on the bridge member ports, and the bridge itself is done with the following commands.

.. code-block:: bash

    bridge vlan add vid ${vid} dev ${PORTA}
    bridge vlan add vid ${vid} dev ${PORTB}
    bridge vlan add vid ${vid} dev ${BRIDGE} self

The `self` flag is required when configuring the VLAN on the bridge interface itself.

Regarding deletion of the VLANs, the following commands can be run.

.. code-block:: bash

    bridge vlan del vid ${vid} dev ${PORTA}

And detaching the ports from the bridge is done via

.. code-block:: bash

    ip link set ${PORTA} nomaster

The configuration with `systemd-networkd` can be done with the following files, under the `/etc/systemd/networkd` directory.

.. code-block:: bash

  swbridge.netdev:

  [NetDev]
  Name=swbridge
  Kind=bridge
  
  [Bridge]
  DefaultPVID=1
  VLANFiltering=1

For `systemd-networkd`, files with the `.netdev` extension specify the configuration for Virtual Network Devices. Under the `[NetDev]` section, the `Name` field specifies the name for the device to be created, and the `Kind` parameter specifies the type of interface that will be created. More information can be seen under the `systemd-networkd .netdev man page <https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#Supported%20netdev%20kinds>`_. Under the `[Bridge]` field, similar parameters as the ones used for `iproute2` are used. To configure VLANs in the Bridge interface, a `.network` file must be used, as the following example.

.. code-block:: bash

  swbridge.network:

  [Match]
  Name=swbridge
   
  [BridgeVLAN]
  PVID=1
  EgressUntagged=1
  VLAN=1-10

Attaching ports to a bridge with systemd-networkd is done similarly, using the `.network` files. The following example demonstrates how.

.. code-block:: bash

  port1.network:

  [Match]
  Name=port1
  
  [Network]
  Bridge=swbridge
  
  [BridgeVLAN]
  PVID=1
  EgressUntagged=1
  VLAN=1-10

This file would configure a single slave port to the configured bridge. `systemd-networkd` allows for matching all ports as well, by using the `Name=port*` alternative, which would match on every baseboxd port, and enslave them all to the bridge. The `VLAN=1-10` will configure the range from `VLAN=1` to `VLAN=10`. Single values can obviously be configured as well, by specifying just a single value.

.. todo:: add example output from bridge command, and flow tables

Switch VLAN Interface
---------------------

.. code-block:: bash

       +-----------+
       |swbridge.10|
       +-----+-----+
             |
      +------+-------+
      |   swbridge   |
      ++------------++
       |            |
  +----+--+      +--+----+
  | port1 |      | port2 |
  |VLAN=10|      |VLAN=20|
  +-------+      +-------+


Extending the layer 2 domain to a layer 3 routed network can be done via the Switch VLAN Interfaces (SVI). These interfaces allow for routing inter-VLAN traffic, removing the need for an external router. Attaching these interfaces to the bridge will provide as well a gateway for a certain VLAN. There is a 1:1 mapping between a VLAN and a SVI. Creating these interfaces is done with the following commands, after creation and port attachment to the bridge.

.. code-block:: bash

  # add a link to the previously created bridge with the same VLAN as PORTX
  ip link add link ${BRIDGE} name ${BRIDGE}.${BR_VLAN} type vlan id ${BR_VLAN}

  # allow traffic with the VLAN used on PORTX on the bridge
  bridge vlan add vid ${BR_VLAN} dev ${BRIDGE} self

  # set previously created link on bridge up
  ip link set ${BRIDGE}.${BR_VLAN} up

The IP address for this interface can then be set with.

.. code-block:: bash

  ip address add ${SVI_IP} dev ${BRIDGE}.${BR_VLAN}

The corresponding `systemd-networkd` configuration adds the `[Network]` section on the `swbridge.network` file:

.. code-block:: bash

   swbridge.network:

   [Match]
   Name=swbridge
       
   [BridgeVLAN]
   VLAN=10
   VLAN=20
       
   [Network]
   VLAN=swbridge.10

The interface `swbridge.10` also has a `.netdev` and `.network` pair of files.

.. code-block:: bash

  swbridge10.netdev:

  [NetDev]
  Name=swbridge.10
  Kind=vlan
   
  [VLAN]
  Id=10

  swbridge10.network:

  [Match]
  Name=swbridge.10
  
  [Network]
  Address=10.0.10.1/24

routing
------- 

As a L3-enabled SDN controller, baseboxd can be configured for routing purposes. Examples in this part are added to show how IP addresses (IPv4 and IPv6) and routes can be attached to certain interfaces. Managing static routes is done tipically via `iproute2` and `systemd-networkd`, and the following sections will describe this in more detail. For dynamic routing, BISDN adopted `FRRouting`, to support routing protocols such as BGP and OSPF. Further information can be seen in section :ref:`frrouting`.

IPv4
----

.. warning:: Configuring a Linux box to work as a router assumes that sysctl `net.ipv4.conf.all.forwarding=1`. BISDN Linux has this sysctl already enabled by default, but routing issues should be debugged first by checking the value for this config.

Adding an IP address to a baseboxd interface is done simply by

.. code-block:: bash
  
  ip link set ${PORT} up
  ip address add ${IPADDRESS} dev ${PORT}

Configuring a static route on the interface via `ip route`:

.. code-block:: bash
  
  ip route add ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}

Route and IP address deletion is done via

.. code-block:: bash
  
  ip address del ${IPADDRESS} dev ${PORT}
  ip route del ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}

IPv4 routing in `systemd-networkd` is done using the `[Network]` and `[Route]` sections to the port `.network` file. In the `[Route]` section, the `Gateway=` section *must* be present in the case when DHCP is not used.

.. code-block:: bash

  port1.network:

  [Match]
  Name=${PORT}
   
  [Network]
  Address=${IPADDRESS}

  [Route]
  Gateway=${GATEWAY}
  Destination=${DESTINATION_NETWORK}/${DESTINATION_MASK}

IPv6
----

* [server](./routing/IPv6/01-server)
* [controller](./routing/IPv6/01-controller)

IPv6 is supported natively in BISDN Linux and baseboxd. It provides simpler network provisioning mechanism, due to address auto-configuration and the advantage of building more recent and stable networks. 

IPv6 addresses are composed of 128 bits, separated by eight groups of four hexadecimal digits, for example:

.. code-block:: bash
  
  FE80:0000:0000:0000:0202:B3FF:FE1E:8329 : long version
  FE80::202:B3FF:FE1E:8329 : short version

Prefixes for IPv6 addresses can then be represented similarly to network masks in IPv4, with the notation `<ip adddress>/<prefix>`, where this prefix is an integer between 1-128. Despite having the possibility of configuring prefixes with this entire range, many of the IPv6 advantages brings, like address auto-configuration works solely with the /64 prefix.

There are some specific reserved network addresses, like the `fe80::/10` address family. This block is reserved to be used in Link-Local Unicast addresses, and, in combination with the MAC address of an interface is used to generate a non-routable address used to exchange Router and Neighbor Advertisements, for example.

Similarly to IPv4, there are also some Linux `sysctls` present to control IPv6 behaviour. The forwarding sysctl, `net.ipv6.conf.all.forwarding`, is in BISDN Linux as well `1`, allowing for the switch to forward IPv6 packets. This affects as well the `net.ipv6.conf.<interface>.accept_ra` sysctl, since routers are not designed to accept Router Advertisements, and using them to configure the IPv6 address. Router advertisements (RA) are the periodically transmitted messages upon reception of Router Solicitations sent by hosts. The host then used the information present in these RA messages, like the prefixes and network parameters to auto-configure the addresses on the links and default gateway.

Configuring IPv6 addresses in BISDN Linux, using `iproute2` is done via the following commands

.. code-block:: bash
  
  ip link set ${PORT} up
  ip address add ${IPADDRESS} dev ${PORT}

Configuring the router to transmit RA messages is possible in several ways. One of the supported ways to transmit these messages is via the `Router Advertisement Deamon (radvd)`. The configuration file for this daemon is present on `/etc/radvd.conf`.

.. code-block:: bash

  /etc/radvd.conf:

  interface ${PORT}
  {
          AdvSendAdvert on;
          MinRtrAdvInterval 30;
          MaxRtrAdvInterval 100;
          prefix 2003:db8:1:0::/64
          {
                  AdvOnLink on;
                  AdvAutonomous on;
                  AdvRouterAddr off;
          };
  };

This configuration example selects the `interface` where to send the advertisements on, and the `prefix` it should announce. The interval between each message can also be fine tuned. Further documentation on this tool can be found in `here <https://linux.die.net/man/5/radvd.conf>`_.

Adding a static IPv6 route is done via 

.. code-block:: bash
  
  ip route add ${DESTINATION_NETWORK}/${DESTINATION_MASK} dev ${PORT} via ${GATEWAY}

So, addition and deletion of IP addresses and routes follow the same workflow as in the IPv4 case. In order to check the configured IPv6 routes, the following command must be run

.. code-block:: bash
  
  ip -6 route list

Adding the `-4/6` argument to the call allows to show only the desired routes/ addresses by IP protocol.

For 'systemd-networkd' the configuration file is done the same way.
