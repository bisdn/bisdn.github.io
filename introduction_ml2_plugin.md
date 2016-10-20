# ML2 Plugin
## Introduction
Basebox provides a Neutron ML2 plugin for seamless integration with OpenStack.

## Architecture
OpenStack, through its Neutron service, exposes a lot of information about the virtual networking resources, which we can use to configure the hardware switches serving our OpenStack instance proactively.

Our ML2 plugin reads the available OpenStack networking information and pushes it to an etcd cluster in a format familiar to baseboxd.

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

## OpenStack Interface
The OpenStack Neutron Modular Layer 2 (ML2) plugin is a powerful framework allowing developers to implement new functionalities that work with OpenStack's networking.

As part of the basebox project we have a working implementation of an ML2 plugin extension. Its purpose is to deliver information about the OpenStack network ports and their associated VLANs to baseboxd.

The information made available includes:
* VLAN IDs
* physical network ports
* UUIDs/MAC addresses of the virtual network ports

The information is published by writing it to an etcd cluster, where the structure of the data represents the relationship between the data values. Check the example bellow:

```text
/
├── VID_1
│   └── physical_port_3
│        └── virtual_port_mac_1
├── VID_2
│   └── physical_port_1
├── VID_3
│   └── physical_port_4
│        └── virtual_port_mac_3
│        └── virtual_port_mac_7
└── VID_4
    └── physical_port_2
```
To find out more about etcd please check [the Github repo](https://github.com/coreos/etcd).

The implementation of our ML2 plugin extension can be found [here](https://gitlab.bisdn.de/basebox/car_ml2_mecha_driver).

## baseboxd Interface

The data stored in etcd is consumed by the *etcd_connector* service, running baseboxd and other basebox services. The *etcd_connector* then creates systemd-networkd configuration files, which will cause systemd-networkd to configure the tap interfaces watched by baseboxd. Subsequently, baseboxd will receive netlink event notifications informing it of any changes made to the tap interfaces.

```text
.                  +---------+---------------------------------------------------+
                   | basebox |                                                   |
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

More details on this can be found in the gitlab repository for for the [*etcd_connector*](https://gitlab.bisdn.de/basebox/vlantranslate).

## Additional Resources
* [Neutron ML2 Wiki](https://wiki.openstack.org/wiki/Neutron/ML2)
* [Neutron Github](https://github.com/openstack/neutron)
* [etcd Documentation](https://github.com/coreos/etcd/blob/master/Documentation/docs.md)
* [etcd Github](https://github.com/coreos/etcd)
* [*etcd_connector* repository](https://gitlab.bisdn.de/basebox/vlantranslate)
* [ML2 Plugin Extension Repository](https://gitlab.bisdn.de/basebox/car_ml2_mecha_driver)
