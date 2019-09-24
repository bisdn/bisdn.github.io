.. _physical_testing::

####################
Install BISDN Fabric
####################

Prerequisites
^^^^^^^^^^^^^

Before you start the configuration, ensure you have the following things ready:
  1. 2x SDN controller servers
  2. 2x Basebox-compatible switches running BISDN Linux Distribution
  3. 1x management switch with at least 4 1G ports available (RJ45)
  4. 1x SFP+ DAC cable
  5. 2x QSFP DAC cable
  6. 6x RJ45 network cables (at least CAT5, recommended CAT6)
  7. SFP+ DAC cables to for switch-uplink and switch-server connectivity (usable ports)

Hardware installation
^^^^^^^^^^^^^^^^^^^^^
Once you have all the pieces ready, you can start rack-mounting and cabling your Basebox hardware.

Below you can see a connectivity graph representing a basic Basebox configuration and cable layout, which you can refer to during installation.

Graph of the physical switch-controller connectivity.

Read on for step-by-step installation instructions.

Install the management switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you are using a pre-existing management switch (prerequisites item 3) to carry the Basebox control traffic:
- dedicate 4 ports on your management switch to the Basebox setup. The 4 ports must be on the same VLAN, separating them from other types of traffic.

If you are introducing a dedicated switch for this role:
- mount it and connect it before proceeding.

Locate the management switch in the place most suitable for your setup's needs, bearing in mind that both the SDN controller servers and Basebox switches will be connected to it. The switch will not need to have an uplink of any sort for Basebox, however you may want to connect it to your management infrastructure for configuration and monitoring purposes.

For details on configuring the management switch, please refer to the "[Configure the management network](#configure-the-management-network-for-control-traffic)" section.

SDN controller server installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Rack mounting
+++++++++++++

Rack mount the SDN controller servers. When planning their placement, remember that the two units will be connected together (via an SFP+ DAC cable).

Connecting to the management network
++++++++++++++++++++++++++++++++++++

Each SDN controller server should have their first network port connected to the management network (marked green on the connectivity graph above).
This is done using 2 of the 6 CAT5 RJ45 cables we prepared earlier (prerequisites item 6).
The SDN controller servers are configured to look for a local DHCP server on these interfaces. 

Connecting the SDN controller servers together
++++++++++++++++++++++++++++++++++++++++++++++

The two SDN controller servers should be connected directly to one another. This connection is used to maintain the state of the HA setup (active/stand-by). 
Connect the two servers with the prepared SFP+ DAC cable (prerequisites item 4), plug it into the bottom SFP+ socket on each server (marked gray on the connectivity graph above).

Connecting to the Basebox switches
++++++++++++++++++++++++++++++++++

Finally connect one, and only one, of the remaining 5 Ethernet ports (marked yellow on the connectivity graph above) on both of the SDN controller servers to the management switch (prerequisites item 3). This switch will be used to carry the OpenFlow control traffic between the SDN controller servers and the Basebox switches. Refer to the "[Configure the management network](#configure-the-management-network-for-control-traffic)" section for further details on the management switch configuration.

Power on
++++++++

When all is connected, you may plug in the power cords and power on the SDN controller servers. You may also connect the IPMI ports (marked purple on the connectivity graph above) as necessary.

Install the Basebox switches
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Rack mount
++++++++++

Rack mount the switches in a way most suitable for your setup. Refer to the specific switch manual for instructions to assemble and rack mount this unit.

Connecting the Basebox switches together
++++++++++++++++++++++++++++++++++++++++

Connect the two switches together with a pair of QSFP DAC cables (prerequisites item 5). Be aware that their location varies on switch-by-switch basis. The connectivity graph shown above presents the layout of a Quanta T3048-LY8 switch. The setup also works with just one interconnect link. Please note that when using only one interconnect cable, once installed and the setup is running, it should not be unplugged. Unplugging it during runtime can result in erroneous behaviour of the setup. If two or more interconnects are installed, it is safe to unplug them as long as at least one interconnection remains installed.

Connecting the Basebox switches to the SDN controllers
++++++++++++++++++++++++++++++++++++++++++++++++++++++

Connect the management ports on both the switches with CAT6 cables (prerequisites item 6) to our management switch (prerequisites item 3). Again, the management switch will be used to carry the OpenFlow control traffic between the SDN controller servers and the Basebox switches. Refer to the "[Configure the management network](#configure-the-management-network-for-control-traffic)" section for further details on the management switch configuration.

Power on
++++++++

At this point the switches are installed. However, before powering them on, the management switch (i.e. the control traffic network) has to be configured (required step).

Configuration
^^^^^^^^^^^^^

Once the setup is wired up, you can proceed to perform any configuration needed before you start all the devices and begin the operation of Basebox.

Configure the management network (for control traffic)
++++++++++++++++++++++++++++++++++++++++++++++++++++++

Once the management switch (prerequisites item 3) is in place and you have the SDN controller servers and the Basebox switches connected to it, you can start the configuration process.

The SDN controller servers are pre-configured to hand out the IP addresses and load correct images onto the switches. This is done through a DHCP server residing on the SDN controller servers, which use the vendor class identifier DHCP option to provide each switch with the correct image.

To facilitate the exchange described here, you need to provide a dedicated layer 2 domain for the SDN controller servers and Basebox switches, for example, a dedicated VLAN configured on the 4 ports of the management switch used by the four devices in question. For exact instructions refer to the documentation of the management switch used.

Configuring the controller servers
++++++++++++++++++++++++++++++++++

The Basebox devices are shipped with a document providing the login details (and other crucial information) for the SDN controller servers and Basebox switches.

Use this information to configure your internal DHCP and DNS servers as necessary, to obtain access to the SDN controller servers via SSH. You should gain access to the SDN controller servers only through the management network connection (marked green on the graph) or using IPMI (marked purple on the graph).
