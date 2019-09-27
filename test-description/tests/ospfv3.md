.. _ospfv3::

OSPFv3 (Open Shortest Path First for IPv6 networking)
=====================================================

OSPFv3 is the protocol providing OSPF routing mechanisms for IPv6 networks.

OSPFv3 setup
^^^^^^^^^^^^

.. image:: ../testbed/images/ospfv3_setup.png
  :scale: 40 %
  :align: center

OSPFv3 configuration
^^^^^^^^^^^^^^^^^^^^

OSPFv3 must first be enabled in `/etc/frr/daemons` file. The relevant files for this test case must then be
configured, `/etc/frr/zebra.conf` and `/etc/frr/osfp6d.conf`. 

.. code-block:: bash

  zebra=yes
  bgpd=no
  ospf6d=yes
  ...
  vtysh_enable=yes
  zebra_options="  -A 127.0.0.1 -s 90000000"
  ...

The zebra file will configure IP addresses on the interfaces, with the configuration snippet. IP addresses
are configured across ftest using different mechanisms. It is not required that the same tools are used,
just that the system is correctly configured for the connectivity tests. The following configurations allow
setting up the Router neighboring discover packets, and IP address autoconfiguration.

.. code-block:: bash

  interface port1
    no shutdown
    no ipv6 nd suppress-ra
    ipv6 nd prefix 2003:db01:1::/64

Regarding `/etc/frr/ospf6d.conf`, the configuration here must specify the point-to-point parameter in the
interface specific section, to enable the protocol on the port53 link between the two baseboxes.
The redistribute connected command is a "smart" flag by FRR, that will redistribute every network configured
on the router.

.. code-block:: bash

  interface port53
    ipv6 ospf6 mtu-ignore
    ipv6 ospf6 network point-to-point
  !
  router ospf6
  	ospf6 router-id {{router_id}}
  	interface port53 area 10.10.10.10
  	redistribute connected
  exit

OSPFv3 expected result and debugging
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Analogous to the previous protocols debugging commands, we can run the following commands to verify the configuration.

.. code-block:: bash

  (vtysh) show ip ospf sum
  
  (vtysh) show ip ospf neighbors
  
  ip route
