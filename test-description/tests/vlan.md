.. _vlan:

VLAN switching
==============

The VLAN setup in ftest is the test case that handles the bridging component of baseboxd, creating the 
bridge on the controllers, and provides L2-connectivity for two leaf switches and servers. 

VLAN setup
^^^^^^^^^^

The developed salt states for this test case deploy the following setup on the lab hardware

![vlan-setup][vlan-setup]

VLAN configuration
^^^^^^^^^^^^^^^^^^

This test is absent of any exterior tools for setting it up, just requiring iproute2 and the running baseboxd. By creating a 
bridge and attaching the baseboxd's access ports to it, a large switching fabric is created. Furthermore, by manipulating internal
salt representation and treatment of pillar data, we can pass an arbitrary number of VLANs, to provide flexiblity in how we test.

The bridge present in the figure *must* have the `vlan_filtering 1` value set, otherwise the test will not pass. This bridge
must as well be configured with the desired VLANs as well, to be able to forward tagged traffic with that VLAN. Interface creation
on the servers must as well be correspondent to the number of VLANs willing to test, and the IP addressing for each interface.VLAN
is correctly handed over.

.. image:: ../testbed/images/vlan_setup.png
  :scale: 40 %
  :align: center
