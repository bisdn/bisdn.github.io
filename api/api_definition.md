# API Definition

## Introduction
The Basebox configuration information is stored in a highly available [etcd][etcd_gh] cluster.
The access to this etcd cluster is open to the Basebox users and effectively provides an API for configuring Basebox, via the generated systemd-networkd files.
Using etcd as a means of configuration allows us to reliably store the configuration information, track the configuration changes and react to them.
It stores information in a directory-like structure, and each 'directory' and 'leaf' data node holds a modification index.
The *etcd connector* uses this index to track changes to the data structure, thus allowing it to react to changes as they happen.

For more specific information on etcd data structure and reading/writing mechanisms please refer to [etcd documentation][etcd_docs].

## Configuration data structure
Basebox enforces that the data in etcd is stored in the following format:

```text
/directory structure/

/<maindir>/<namespace>/<portname>/<type>/<config>

# example:
/basebox/ports/portAABBCCDD/vlan/42/token ''
```
### namespaces

The main directory in `/<maindir>` allows for creating many subdirectories that will contain the different types of configuration that etcd_connector will accept. We name these different subdirectories as `namespaces`, and
currently we support the `ports` namespace for setting port configuration.

### portname
The etcd directory in `/<maindir>` stores a list of directories, labeled with the names of the physical ports: `<physical_port_id>`. Each physical port ID is a unique value, only one entry per physical port can exist.  The port
 naming done by CAWR is described [here](../introduction/introduction_cawr.html#port-mapping).

### type

Ports can have multiple configuration options, so it is necessary to specify the type of configuration that should be applied to the port. This will vary according to namespace, in order to reduce possible collisions between 
different configs. Currently supported under the ports namespace is the VLAN and L3 types. This will set the VLAN tags per port, and the IP addresses to each interface respectively.

### config 

Under the config we can specify the information we desire to configure under the port. In the following sections we describe how to configure VLANs and IP addresses on ports.

#### VLANs

Each physical port directory can hold zero or more directories, labeled with the names of the VLAN IDs: `<vlan_id>`. Since we can have the same VLAN ID enabled on multiple ports, it is a value unique to each `<physical_port_id>` directory but not globally unique. Valid VLAN IDs are in the range of 1-4095. In case you are using CAWR the range will be reduced, see [Configuring the controller servers](../setup/setup_physical.html#configuring-the-controller-servers) or [Failover](../introduction/introduction_cawr.html#failover).

Each VLAN ID directory can hold zero or more files (leaf nodes), labeled: `<enabling_token>`. The contents of the node can be set to `''` (empty), since they are currently not evaluated. A VLAN ID is only enabled in case an enabling_token exists.

#### IP addresses

For IP configuration, we support setting a single address on each `<physical_port_id>`. To use this field, set the `<config>` parameter as `<IP address>/<netmask>`, like the following example:

```
# example:
/basebox/ports/portAABBCCDD/l3/10.0.0.1/24 ''
```

```text
/ etcd directory structure example /

basebox
└── ports
    ├── portAABBCCDD
    │   ├── l3
    │   │   └── 10.0.0.2
    │   │       └── 24
    │   └── vlan
    │       ├── 2
    │       │   └── enabling_token '' <- / enables vlan 2  /
    │       └── 3                     <- / vlan 3 disabled /
    │                              
    └── portAABBCCDE
        ├── l3
        │   └── 10.0.0.1
        │       └── 24 ''             <- / Enable address on the interface  /
        └── vlan
            ├── 2
            │   └── enabling_token ''
            ├── 3
            │   └── enabling_token ''
            ├── 4
            │   └── enabling_token ''
            └── 5
                └── enabling_token ''
```

### Configuration triggers
The most important events, triggering configuration changes of the vlan configuration on the switches, is the addition and removal of `<enabling_token>` nodes to and from vlan_id directories. Currently, the `etcd_connector` checks for the number `<enabling_token>` nodes in the `<vlan_id>` directory every time a `<vlan_id>` is modified, and:
* removes the vlan from a port if the number of `<enabling_token>` = 0
* adds the vlan to a port if the number of `<enabling_token>` >= 1

To give a concrete example, our ML2 mechanism driver currently uses OpenStack VM UUIDs as `<enabling_token>` nodes. This way it indicates which VMs are using a given VLAN on a given server port. Also, if no VMs are using the VLAN/port combination, the corresponding enabling_token will be removed from etcd and the VLAN from the port.

*(In future releases our ML2 mechanism driver will use an OpenStack VM's interfaces' MAC addresses as enabling tokens)*

## Example actions
etcd can be interacted with using a range of interfaces.
The tested interfaces are:
* etcdctl command line tool
* REST interface
* etcd-python module

### Add enabling_token
etcdctl:
```shell
etcdctl set /basebox/ports/<physical_port_id>/<vlan_id>/<enabling_token> ''
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/basebox/ports/<physical_port_id>/<vlan_id>/<enabling_token> -XPUT -d value=""
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.write('/basebox/ports/<physical_port_id>/<vlan_id>/<enabling_token>', '')
```

### Remove enabling_token
etcdctl:
```shell
etcdctl rm /basebox/ports/<physical_port_id>/<vlan_id>/<enabling_token>
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/basebox/ports/<physical_port_id>/<vlan_id>/<enabling_token> -XDELETE
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.delete('/basebox/ports/<physical_port_id/<vlan_id>/<enabling_token>')
```

### List configuration
etcdctl:
```shell
etcdctl ls --recursive /basebox/ports
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/basebox/ports?recursive=true
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.read('/basebox/ports/<physical_port_id/<vlan_id>/<enabling_token>', recursive=True)
```

## Additional resources
* [etcd Documentation][etcd_docs]
* [etcd Github][etcd_gh]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[etcd_docs]: https://github.com/coreos/etcd/blob/master/Documentation/docs.md (etcd Documentation)
[etcd_gh]: https://github.com/coreos/etcd (etcd Github)