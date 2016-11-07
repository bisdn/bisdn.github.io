# Physical setup
## Prerequisites
Before you start the configuration ensure you have the following things ready:
1. 2x Caros controller servers
2. 2x Basebox-compatible switches running BISDN Linux
3. 1x "management switch" with at least 4 1GB ports available (RJ45)
4. 1x SFP+ DAC cable
5. 2x QSFP DAC cable
6. 6x RJ45 network cables (at least CAT5, recommended CAT6)
7. SFP+ DAC cables to for switch-uplink and switch-server connectivity (usable ports)

## Hardware installation
Once you have all the pieces ready, you can start rack-mounting and cabling your Basebox hardware.

Below you can see a graphical representation of a basic Basebox configuration, which you can refer to during installation.

![Graph of the physical switch-controller connectivity.][csc]

Read on for step-by-step installation instructions.

### Install the management switch
If you are using a pre-existing "management switch" (prerequisites item 3) to carry the Basebox control traffic, then skip this stage. If you are introducing a dedicated switch for this role, then please mount it and connect it before proceeding.
Locate it in the place most suitable for your setup's needs, bearing in mind that both the Caros servers and Basebox switches will be connected to it. The switch will not need to have an uplink of any sort for Basebox, however you may want to connect it to your management infractructure for configuration and monitoring purposes.

### Install the Caros controller servers
Rack mount the Caros server controllers. When planning their placement remember that the two units will be connected together (via an SFP+ DAC cable).

Each Caros server should have their first network port (labeled `ge0p0`) connected to the management network (marked green on the connectivity graph).
This is done using 2 of the 6 CAT5 RJ45 cables we prepared earlier (prerequisites item 6).
The servers are configured to look for a local DHCP server on these interfaces. This connection should provide our Caros servers with access to the OpenStack [Neutron][neutron_gh] [ML2 plugin][neutron_wiki].

The two Caros servers should be connected directly to one-another. This connection is used to maintain the state of the HA setup (active/stand-by). Connect the two servers with the prepared SFP+ DAC cable (prerequisites item 4), plug it into the left-most SFP+ socket on each server (as ilustrated).

Lastly connect the second-in-the-row ethernet port (labeled `ge0p1`) on either of the Caros servers to our "management switch" (prerequisites item 3). This switch will be used to carry the OpenFlow control traffic between the Caros servers and the Basebox switches. Refer to the "[Configure the management network](#configure-the-management-network)" section for further details on the "management switch" configuration.

When all is connected, you may plug in the power cords and power on the servers. You may also connect console ports (labeled `console` on the server front panel) as necessary.

### Install the Basebox switches
Rack mount the switches alongside your OpenStack compute nodes in a way most suitable to your setup.

Connect the two switches together with a pair of QSFP DAC cables (prerequisites item 5). Be aware that their location varies on switch-by-switch basis. The illustration shown above presents the layout of a Quanta T3048-LY8 switch. The setup also works with just one interconenct link. Please note that when using either, one or two interconnect cables, once installed and the setup is running, they should not be unplugged. Unplugging one (or both) during runtime can result in erroneous behaviour of the setup.

Connect the management ports on both the switches with with CAT6 cables (prerequisites item 6) to our "management switch" (prerequisites item 3). Again, this switch will be used to carry the OpenFlow control traffic between the Caros servers and the Basebox switches. Refer to the "[Configure the management network](#configure-the-management-network)" section for further details on the "management switch" configuration.

At this point the switches are installed. However before powering them on the management switch (i.e. the control traffic network) has to be configured (required step) and the Openstack compute node servers should be plugged into the switches (recommended step).

### Connect the OpenStack compute node servers
The servers running our OpenStack instance have to be connected to the Basebox switches using SFP+ DAC cables (prerequisites item 7). The presence of 2 Basebox switches in the setup enables HA features. In order to take advantage of HA, the following must be performed on each server:
* configure link aggregation on 2 ports (LACP, slow LACPDU rate recommended)
* connect each of the ports in the LACP bond to an alternative switch (never to the same switch, trunking is not supported)
LACP bonds will be automatically detected and configured in the control plane.

Non-HA configuration support is also available. One may choose to connect any OpenStack compute nodes to a Basebox switch with a single SFP+ DAC cable with no extra configuration needed on the server side.

Repeat the above steps for each compute node.

## Configuration
Once the setup is wired up, we can proceed to perform any configuration needed before we start all the devices and begin the operation of Basebox.

### Configure the management network (for control traffic)
Once the management switch (prerequisites item 3) is in place and we have the controller servers and the switches connected to it we can start the configuration process.

The Caros controller servers are pre-configured to hand out the IP addresses and load correct images onto the switches. This is done through a DHCP residing on the Caros servers, which use the vendor class identifier DHCP option to provide each switch with the correct image.

To facilitate the exchange prescribed here we need to provide a dedicated layer 2 domain for the Caros servers and Basebox switches. For example, a dedicated vlan configured on the 4 ports of the "management switch" used by the four devices in question. For exact instructions refer to the documentation of the "management switch" used.


### Configuring the controller servers
Provided with the Basebox devices was a document noting the login details (and other crucial information) for the Caros servers and Basebox switches.

Use this information to configure your internal DHCP and DNS servers as necessary, to obtain access to the Caros controller servers via ssh. You should gain access to the servers only though the management network connection (marked green on the graph).

[baseboxd][baseboxd_gh] and CAWR can start operation without any intervention from the user at this point. Basebox can detect LACP bonds on the switch interfaces and obtain configuration information from the OpenStack ML2 integration (once this is also configured).

However, the configuration of OpenStack uplink ports still remains a manual step. Any connections that go outside of the bounds of the OpenStack instance have to be declared in CAWR's main configuration file.

To configure the uplink ports, you have to log into each of the Caros controller servers and repeat the following steps:

```shell
cd /etc/sysconfig/
sudo vi car_config.yaml
```
*The switches were pre-configured with unique DPIDs. They can be found on the information leaflet provided with each switch.*

When in the CAWR config file edit the `externalports` section by adding the uplink ports. Please note that `port_extern_[n]` labels corespond to the physical port number labels as they appear on each Basebox-attached switch. The `dpdi[n]` labels correspond to the DPID of each respective switch.

Example of a standalone, single cable uplink (no port bonding):

```
externalports:
# - [Interfacename, dpid1, port_extern_1, dpid2, port_extern_2]
- [ uplink_port, 1,41 ]

```

Example of a bonded uplink port, configured using LACP (bonding must be configured on the external device providing the uplink):

```
externalports:
# - [Interfacename, dpid1, port_extern_1, dpid2, port_extern_2]
- [ uplink_port, 1, 41, 2, 36 ]

```

After adding the above configuration, save and quit the file, then restart the CAWR service:

```shell
sudo systemctl restart CAWR
```

At this point, the `uplink_port` port should appear on the active controller server. It's presence can be confirmed by executing the IP command:

```
ip link
```

Now, through the `uplink_port` port we can manage the OpenStack uplink connection and Basebox will take care of propagating the changes down to the switches.

### Configuring the OpenStack ML2 integration
The [Basebox ML2 mechanism driver][ml2] is provided in form of a linux package (for now only debian .deb, others coming soon).

Once the .deb file is obtained and placed on the OpenStack Neutron host machine, the `basebox_ml2_mechanism_driver` package can be installed from the command line, as follows:
```shell
sudo dpkg -i basebox_ml2_mechanism_driver.deb
```

Once installed, the new mechanism driver must be configured. The mechanism driver generates a default config file at the following location:
```
/usr/lib/python2.7/site-packages/neutron/plugins/ml2/drivers/mech_car.conf
```

To edit the file:

```shell
cd /usr/lib/python2.7/site-packages/neutron/plugins/ml2/drivers/
sudo vi mech_car.conf
```

The Neutron ML2 plugin assumes that the OpenStack compute nodes are configured with DNS entries.

The newly generated config file has to be updated with relevant entries.
It consists of 5 sections:
* northbound (should remain unchanged)
* etcd (has to be updated)
* ssh (should remain unchanged)
* neutron (has to be updated)
* portmap (has to be updated)

Below we can observe a sample config file with dummy values that need to be replaced.

```
[northbound]
type=etcd

[etcd]
host=your.caros.basebox.server.de
port=2379
maindir=ml2_cawr

[ssh]
basebox_host=your.caros.basebox.server.de
basebox_port=2222
basebox_user=root
basebox_passw=password
basebox_dir=/etc/systemd/network/vlan/

[neutron]
hosts=example1.openstack.node.de,example2.openstack.node.de

[portmap]
example1.openstack.node.de=port1
example2.openstack.node.de=port2
example3.openstack.node.de=port3
example4.openstack.node.de=port4
```

Once the file is modified, save and quit, then restart the Neutron service.

```shell
sudo systemctl restart neutron
```

## Customer support
If at any point during installation or configuration of your basebox setup you get stuck or have any questions, please contact our customer support via email: [support@basebox.freshdesk.com](support@basebox.freshdesk.com).

## Additional resources
* [baseboxd github][baseboxd_gh]
* [etcd github][etcd_gh]
* [Neutron Github][neutron_gh]
* [Neutron ML2 Wiki][neutron_wiki]
* [ML2 Plugin extension repository][ml2]

[baseboxd_gh]: www.github.com/bisdn/basebox (baseboxd GitHub Repository)
[etcd_gh]: https://github.com/coreos/etcd (etcd GitHub repository)
[neutron_wiki]: https://wiki.openstack.org/wiki/Neutron/ML2 (Neutron ML2 Wiki)
[neutron_gh]: https://github.com/openstack/neutron (Neutron Github)
[ml2]: https://gitlab.bisdn.de/basebox/car_ml2_mecha_driver (ML2 Plugin Extension Repository)
[csc]: images/caros-switch-connectivity.png (Graph of the physical switch-controller connectivity.)
