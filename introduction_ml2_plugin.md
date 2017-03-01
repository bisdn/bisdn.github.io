# ML2 Plugin
## Introduction
Basebox provides a Neutron ([GitHub][neutron_gh], [Wiki][neutron_wiki]) ML2 plugin for seamless integration with OpenStack.

## Architecture
OpenStack, through its Neutron service, exposes a lot of information about the virtual networking resources, which we can use to configure the hardware switches serving our OpenStack instance proactively.

Our integrated ML2 plugin reacts to every networking information change in Neutron and pushes the changes to an etcd cluster in a format familiar to the *[etcd_connector][]* daemon.
On the other side, the *etcd_connector* daemon watches for changes to the etcd data structures and applies changes to the baseboxd networking abstraction through systemd-networkd.

```text
.+------------+                     +------------------+.
++ OpenStack  |                     | baseboxd         <+
|-------------+                     +-------------------|
|| Neutron    |     +---------+     | systemd-networkd ||
|-------------+     | etcd    |     +-------------------|
+> ML2 Plugin +-----> Cluster +-----> etcd_connector   ++
.+------------+     +---------+     +------------------+.
```

## OpenStack interface
The OpenStack Neutron Modular Layer 2 (ML2) plugin is a powerful framework allowing developers to implement new functionalities that work with OpenStack's networking.

As part of the Basebox project we have a working implementation of an ML2 plugin extension. Its purpose is to deliver information about the OpenStack network ports and their associated VLANs to baseboxd.

The information made available includes:
* VLAN IDs
* physical network ports
* UUIDs/MAC addresses of the virtual network ports

The information is published by writing it to an etcd cluster, where the structure of the data represents the relationship between the data values. Check the example below:

```text
/
├── physical_port_1
│   └── VID_3
│        └── virtual_port_mac_1
├── physical_port_2
│   └── VID_1
├── physical_port_3
│   └── VID_4
│        └── virtual_port_mac_3
│        └── virtual_port_mac_7
└── physical_port_4
    └── VID_2
```
To find out more about etcd please check the [Github repo][etcd_gh] and [official documentation][etcd_docs].

The implementation of our ML2 plugin extension will be release as OpenSource later.

## baseboxd interface

The data stored in etcd is consumed by the *etcd_connector* service, running baseboxd and other Basebox services. The *etcd_connector* then creates systemd-networkd configuration files, which will cause systemd-networkd to configure the tap interfaces watched by baseboxd. Subsequently, baseboxd will receive netlink event notifications informing it of any changes made to the tap interfaces.

```text
.                  +---------+---------------------------------------------------+
                   | Basebox |                                                   |
                   +---------+                                                   |
+--------------+   | +--------------+                                +--------+  |
| etcd cluster +----->etcd_connector|                                |baseboxd|  |
+--------------+   | +-----+--------+                                +----^---+  |
                   |       |                                              |      |
                   |       |         +----------------+                   |      |
                   |       +--------->systemd-networkd|                   |      |
                   | config files    +-------+--------+                   |      |
                   |                         |                            |      |
                   |                         |         +------------+     |      |
                   |                         +--------->linux kernel+-----+      |
                   |                         netlink   +------------+   netlink  |
                   |                                                             |
                   +-------------------------------------------------------------+

```

To apply configuration changes to the tap interfaces, systemd-networkd must be restarted when its configuration files are altered. The *etcd_connector* daemon runs a dedicated thread, periodically triggering an event to check if the systemd-networkd needs to be restarted. Currently in the configuration this delta time is 2 seconds. Whenever new systemd-networkd configuration files are generated, the thread restarts networkd and the VLAN tags added to the ports will activate. The removal of the tags is handled by the `bridge` command, as systemd-networkd is currently not able to remove VLAN tags. If the network configuration continuously changes, networkd will be restarted at most every 2 seconds.

More details on this can be found in the gitlab repository for for the *etcd_connector*.

## Additional resources
* [*etcd_connector* Repository][etcd_connector]
* [etcd Documentation][etcd_docs]
* [etcd Github][etcd_gh]
* [Neutron Github][neutron_gh]
* [Neutron ML2 Wiki][neutron_wiki]

[neutron_wiki]: https://wiki.openstack.org/wiki/Neutron/ML2 (Neutron ML2 Wiki)
[neutron_gh]: https://github.com/openstack/neutron (Neutron Github)
[etcd_docs]: https://github.com/coreos/etcd/blob/master/Documentation/docs.md (etcd Documentation)
[etcd_gh]: https://github.com/coreos/etcd (etcd Github)
[etcd_connector]: https://gitlab.bisdn.de/basebox/etcd_connector (*etcd_connector* repository)
