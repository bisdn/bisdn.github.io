# Existing API clients - Neutron ML2 plugin
## Neutron introduction
Neutron is the OpenStack module which manages the networking layer of OpenStack. It configures the internal Linux networking while providing an interface to the other OpenStack modules to manage it. It also provides an externally accessible API, including a plugin system.
Basebox takes full advantage of the Neutron ML2 plugin API. Our mechanism driver for the ML2 plugin exposes VLAN and physical port configuration to Basebox using the etcd-based API.

To find out more about Neutron we refer the reader to the [Neutron GitHub Repo][N_GH] and [Neutron Wiki][N_WIKI]

## Modular Layer 2 (ML2) plugin
Modular Layer 2 (ML2) is a Neutron plugin providing a framework for developers to write their own extensions. It gives the developers an API in the form of a set of abstract python classes. Most notably:
* [TypeDriver metaclass][TDM]
* [MechanismDriver metaclass][MDM]
* [ExtensionDriver metaclass][EDM]

As well as classes that govern the format of different layer 2 network-related information provided by the ML2 plugin:
* [NetworkContext metaclass][NCM]
* [SubnetContext metaclass][SCM]
* [PortContext metaclass][PCM]

Each network type available through Neutron (as described [here][OSN_INTRO]) is governed by an implementation of a TypeDriver class. TypeDrivers manage type-specific network information and states.
We have implemented our extension based on the MechanismDriver metaclass.
Each respective MechanismDriver provides additional mechanisms which are activated by certain events within the Neutron module. In our case, we write configuration information into Basebox upon discovering changes to the VLAN configuration on the physical, Neutron-managed, server ports.
We use the network, subnet and port context abstractions to access the relevant layer 2 network information and make it available to baseboxd through our etcd API. Continue reading for implementation details.

The purpose of the Type Driver and Mechanism Driver classes are described in the wiki, [here][TD_WIKI] and [here][MD_WIKI] respectively.

To find out more about the Modular Layer 2 plugin, do refer to the [ML2 GitHub Repo][N_ML2_GH] and [ML2 wiki][N_ML2_WIKI].

## Basebox ML2 mechanism driver
As noted in the previous section, we use the MechanismDriver interface to gain access to the Neutron information.

```text
/ OpenStack Neutron-to-ML2_Mechanism_Driver Interaction /

+-----------------------------------------------------------------+
|OpenStack                                                        |
|                                                                 |
|  +-----+  +-------+    +----------------------------+  +-----+  | +
|  |Nova |  |Cinder |  + |          Neutron           |  | ... |  | | OpenStack Modules
|  +-----+  +-------+  | +----------------------------+  +-----+  | +
|  | ... |  |  ...  |  | |                            |           | +
|  +-----+  +-------+  | |        ML2 Plugin          |           | |
|                      | |                            |           | | OpenStack
|                      | +----------------------------+           | | Module
|                      | |                            |           | | APIs
|                      | |  ML2 Mechanism Driver API  |           | |
|                      | |                            |           | +
|                      | +----------------------------+           |
|                      | |                            |           | + Basebox
|                      v |Basebox ML2 Mechanism Driver|           | | Plugin
|                        |                            |           | + Implementation
|                        +------------+---------------+           |
|                                     |                           |
+-----------------------------------------------------------------+
                                      |
                         +------------v---------------+
                         |   Basebox etcd-based API   |
                         +----------------------------+
```
The MechanismDriver enforces the implementation of two sets of functions per network resource type, per interaction type, in the following format:
* `[create/update/delete]_[network/subnet/port]_precommit`
* `[create/update/delete]_[network/subnet/port]_postcommit`

Neutron ML2 plugin will then execute these functions when adequate events happen. For example, when a port is created it will trigger:
* `create_port_precommit`
* `create_port_postcommit`

In our MechanismDriver implementation we mainly use `create_port_postcommit` and `delete_port_postcommit`.

We use the `etcd` python module to write to our etcd cluster from the MechanismDriver.

### create_port_postcommit
We use the `create_port_postcommit` to consume the information about the created ports. From the `NetworkContext`/`SubnetContext`/`PortContext` classes we extract the physical_port_id, vlan_id and virtual_port_mac_address and post it to our etcd cluster using the available API calls for adding ports, vlan IDs and MAC addresses in the required format.

This is then picked up by our `etcd_connector` on the other baseboxd host to re-configure baseboxd.

### delete_port_postcommit
We use the `delete_port_postcommit` to consume the information about the deleted ports. From the `NetworkContext`/`SubnetContext`/`PortContext` classes we extract the physical_port_id, vlan_id and virtual_port_mac_address and post it to our etcd cluster using the available API calls for removing ports, vlan IDs and MAC addresses in the outlined format.

This is then also picked up by our `etcd_connector` on the other baseboxd host to re-configure baseboxd.

## Additional resources
* [Neutron GitHub][N_GH]
* [Neutron ML2 driver API source (GitHub)][DR_API_SRC]
* [Neutron ML2 Plugin Main GitHub Repository][N_ML2_GH]
* [Neutron ML2 Wiki][N_ML2_WIKI]
* [Neutron plugin API developer documentation][N_P_API]
* [Neutron Wiki][N_WIKI]

**Customer support**: If at any point during the installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](customer_support.html#customer_support)**.

[N_ML2_WIKI]: https://wiki.openstack.org/wiki/Neutron/ML2 (Neutron ML2 Wiki)
[N_ML2_GH]: https://github.com/openstack/neutron/tree/master/neutron/plugins/ml2 (Neutron ML2 Plugin Main Github Repository)
[DR_API_SRC]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py (Neutron ML2 driver API source)
[N_P_API]: http://docs.openstack.org/developer/neutron/devref/plugin-api.html (Neutron plugin API developer documentation)
[N_GH]: https://github.com/openstack/neutron (Neutron Module GitHub Repository)
[N_WIKI]: https://wiki.openstack.org/wiki/Neutron (Neutron Module GitHub Wiki)
[TD_WIKI]: https://wiki.openstack.org/wiki/Neutron/ML2#Type_Drivers
[MD_WIKI]: https://wiki.openstack.org/wiki/Neutron/ML2#Mechanism_Drivers
[TDM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L39 (TypeDriver metaclass source on GitHub)
[MDM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L549 (MechanismDriver metaclass source on GitHub)
[EDM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L930 (ExtensionDriver metaclass source on GitHub)
[NCM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L160 (NetworkContext metaclass)
[SCM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L198 (SubnetContext metaclass)
[PCM]: https://github.com/openstack/neutron/blob/master/neutron/plugins/ml2/driver_api.py#L231 (PortContext metaclass)
[OSN_INTRO]: http://docs.openstack.org/newton/networking-guide/intro-os-networking.html (OpenStack Documentation on )
