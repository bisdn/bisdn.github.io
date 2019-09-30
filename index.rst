.. _basebox:

.. glossary::

  OFDPA
  OpenFlow Data Path Abstraction
    application software component that implements an adaptation layer between OpenFlow and the Broadcom Silicon SDK, `see also <https://github.com/Broadcom-Switch/of-dpa/>`_. baseboxd uses the rofl-common library, available on `github <https://github.com/bisdn/rofl-common>`_. 

  netlink
  libnl
    `Netlink <http://man7.org/linux/man-pages/man7/netlink.7.html>`_ is used to transfer information between the kernel and user-space processes. baseboxd relies on the `libnl library <https://www.infradead.org/~tgr/libnl/doc/api/>`_ to interact with this interface. 

  iproute2
    `iproute2 <https://wiki.linuxfoundation.org/networking/iproute2>`_ is a Linux project offering network and traffic control utilities. It consists of several tools, as the `ip` and `tc`,
    providing network configuration and traffic control commands, respectively. It replaces the older tools `ifconfig`, `route` and bridge, providing more recent tools to interact with kernel
    networking. 

  systemd
  systemd-networkd
    `systemd-networkd <https://www.freedesktop.org/wiki/Software/systemd/>`_ is a part of systemd specifically targeted to manage network configuration. It can configure network devices with 
    a collection of `.network`, `.link` files, usually stored in the `/etc/systemd/networkd` directory. Using `systemd-networkd` allows network administrators to have a consistent and permanent
    network configuration.

  FRR
  FRRouting
    `FRRouting <https://frrouting.org/>`_ is a Linux IP routing suite, providing protocol daemons for BGP, OSPF, IS-IS. Forked from Quagga, this project aims to provide an improved and 
    updated routing stack to operators, with support for recent routing protocol extensions, and updated interface for configuration.

  ONIE
  Open Network Install Environment
    `ONIE <http://onie.org/>`_ provides a network operating system install environment for bare-metal switches. 


############
Introduction
############

.. toctree::
      :glob:

   customer_support
   introduction/introduction_bisdn_linux
   introduction/introduction_baseboxd

.. setup

##############################
Setup and System Configuration
##############################

.. toctree::
      :glob:

   setup/install_switch_image
   setup/setup_standalone

#############
Testing Guide
#############

.. toctree::
      :glob:

    test-description/README.md
    test-description/tests/bgp
    test-description/tests/bgpv6
    test-description/tests/ospfv2
    test-description/tests/ospfv3
    test-description/tests/ipv6-standalone
    test-description/tests/l3-performance
    test-description/tests/l3-standalone
    test-description/tests/vlan
  
#############
Known issues:
#############
.. toctree::
      :glob:

   setup/known_issues


