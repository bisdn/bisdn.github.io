.. _bgp:

BGP (Border Gateway Protocol)
-----------------------------

Leveraging :ref:`FRR` as the routing daemon, the BGP tests will ensure the correct interaction between two controllers and two servers.

BGP configuration
^^^^^^^^^^^^^^^^^

FRR is configured using files, typically on the `/etc/frr/` directory. Each desired protocol has a different configuration file,
where the protocol-specific information can be stored.  This folder will also hold the general configuration files for FRR itself,
like the `daemons` file, used to set the listening addresses for the protocols and as toggle for configuration of each individual
routing protocol/daemon.

.. code-block:: bash

  zebra=yes
  bgpd=yes
  ospfd=no
  ...
  vtysh_enable=yes
  zebra_options="  -A 127.0.0.1 -s 90000000"
  bgpd_options="   -A 127.0.0.1"
  ...

The `/etc/frr/bgpd.conf` file has the protocol specific configs, where the routing information is set up. This routing
information entails all the necessary next-hops, route announcements, and route-filters needed to achieve the configuration.

Setting up the IP addresses on the interfaces on the controller, according to the diagram above, can be done using iproute2
commands. The current ftest workflow allows developers to use their preferred configuration mechanism for link creation, ip
addressing mechanism, and others, as long as the communication to the Linux Kernel is made via the netlink interface.

BGP configuration overview
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  router bgp 65000
   bgp router-id 10.0.254.1
   bgp cluster-id 10.0.254.1
   bgp log-neighbor-changes

router BGP <AS> is the first configuration for bgpd, where we define the Autonomous System (AS) for the routing daemon.
Router id and cluster id are two parameters used to identify the router we are configuring.

.. code-block:: bash

   neighbor fabric peer-group
   neighbor fabric remote-as 65000
   neighbor fabric ebgp-multihop 10
   neighbor 10.0.254.2 peer-group fabric

The neighbor lines configure the remote peer-group we are configuring, even though we are only considering *one* next-hop. 
As per the line `remote-as`, we must consider the same AS number for the remote endpoint, since this will enable iBGP,
ie. BGP session across two nodes configured in the same AS. The last line will finally configure the neighbor.

.. code-block:: bash

 network 10.1.0.0/24
 network 10.1.1.0/24
 network 10.1.2.0/24
 network 10.1.3.0/24
 network 10.1.4.0/24
 network 10.1.5.0/24

The last lines on the configuration file specify the networks that must be announced to the other peer. The other node will 
receive these networks, and learn the appropriate routes to the next-hop. 

BGP expected result and debugging
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

BGP expects a connection through the defined neighbors to port 179 by default. The connection status can be analysed via the FRR shell `vtysh`.

The result of `vtysh` command, `show ip bgp sum` must be:

.. code-block:: bash

  (vtysh) show ip bgp sum

With this command, we see that a neighbor has been successfully learned, and the connection is online and stable.
Debugging the BGP connection might be a tricky process, but guides from `cisco <https://meetings.ripe.net/ripe-44/presentations/ripe44-eof-bgp.pdf>`_.
More information on the bgp neighbors is available via

.. code-block:: bash

  (vtysh) show ip bgp neighbors

The iBGP-learned routes may be checked out if correctly installed on the kernel via

.. code-block:: bash

  ip route

The final debugging information to confirm must be the switch tables, where we must check if baseboxd has correctly translated
the rules on the kernel to OpenFlow flow mods, via `client_flowtable_dump 30`. This is the sole command that must *always* be run
on the switch. The previous commands must be run on the controller/switch, depending where baseboxd is running.
