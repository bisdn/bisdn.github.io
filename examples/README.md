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

* [server](./bridging/01-server)
* [controller](./bridging/01-controller)

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


Extending the layer 2 domain to a layer 3 routed network can be done via the Switch VLAN Interfaces (SVI). These interfaces allow for routing inter-VLAN traffic, removing the need for an external router. Attaching these interfaces to the bridge will provide as well a gateway for a certain VLAN. There is a 1:1 mapping between a VLAN and a SVI. Creating these interfaces is done with the following commands, after creation and port attachement to the bridge.

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

As a L3-enabled SDN controller, baseboxd can be configured for routing purposes. Examples in this folder are added to show how IP addresses (IPv4 and IPv6) and routes can be attached to certain interfaces. 

IPv4
----

* [server](./routing/IPv4/01-server)
* [controller](./routing/IPv4/01-controller)

IPv6
----

* [server](./routing/IPv6/01-server)
* [controller](./routing/IPv6/01-controller)


Free Range Routing
==================

[Free Range Routing](https://github.com/FRRouting/frr), or FRR, is a routing agent for Linux/Unix plaforms, that aggregates several routing daemons, like bgpd and ospfd. 

Currently FRR support in baseboxd, is only tested with bgpd, and in the Free Range Routing folder, a few configuration examples can be seen. Installing FRR can be done, on Fedora and CentOS distributions, by enabling the BISDN FRR copr repository, available [here](https://copr.fedorainfracloud.org/coprs/bisdn/frr/), or the testing version [here](https://copr.fedorainfracloud.org/coprs/bisdn/frr-testing/).

networkd
========

As examples for configuration using systemd-networkd, the files are available under the networkd folder. These files will generate a configuration similar to the one configured on the bridging section.
