# API Definition

## Introduction
The Basebox configuration information is stored in a highly available [etcd][etcd_gh] cluster.
The access to this etcd cluster is open to the Basebox users and effectively provides an API for configuring Basebox.
Using etcd as a means of configuration allows us to reliably store the configuration information, track the configuration changes and react to them.
It stores information in a directory-like structure, and each 'directory' and 'leaf' data node holds a modification index.
The *[etcd connector][etcd_connector]* uses this index to track changes to the data structure, thus allowing it to react to changes in as they happen.

For more specific information on etcd data structure and reading/writing mechanisms please refer to [etcd documentation][etcd_docs].

## Configuration data structure
Basebox enforces that the data in etcd is stored in the following format:

```text
/directory structure/

 directory   directory       directory   key(file)   value(file)
     |           |               |           |           |
     v           v               v           v           v
/<prefix>/<physical_port_id>/<vlan_id>/<enabling_token> ''

# example:
/basebox/ports/portAABBCCDD/42/token ''
```
### physical_port_id
The etcd directory in `/<prefix>` stores a list of directories, labeled with the names of the physical ports: `<physical_port_id>`. Each physical port ID is a unique value, only one entry per physical port can exist.

In the current version the prefix is set to `/<prefix> = /basebox/ports`. The port naming done by CAWR is described [here](introduction_cawr.html#port-mapping).

### vlan_id
Each physical port directory can hold zero or more directories, labeled with the names of the vlan IDs: `<vlan_id>`. Since we can have the same vlan ID enabled on multiple ports, it is a value unique to each `<physical_port_id>` directory but not globally unique. Valid VLAN IDs are in the range of 1-4095. In case you are using CAWR the range will be reduced, see [Failover](introduction_cawr.html#Failover).

### enabling_token
Each vlan ID directory can hold zero or more files (leaf nodes), labeled: `<enabling_token>`. The contents of the node can be set to `''` (empty), since they are currently not evaluated. A VLAN ID is only enabled, in case an enabling_token exists.

```text
/ etcd directory structure example /

/basebox/ports/
              ├── portAABBCCDD
              │   ├─── 2
              │   │    └── enabling_token_2  <- / enables vlan 2  /
              │   └─── 4                     <- / vlan 4 disabled /
              ├── portAABBCCDE
              │   └──  2                     <- / vlan 2 disabled /
              └── portAABBCCDF
                  └─── 3
                       └── enabling_token_2  <- / enables vlan 2  /
                       └── enabling_token_3  <- / enables vlan 2  /

```

### Configuration triggers
The most important events, triggering configuration changes of the vlan configuration on the switches, is the addition and removal of `<enabling_token>` nodes to and from vlan_id directories. Currently, the *etcd connector* checks for the number `<enabling_token>` nodes in the `<vlan_id>` directory every time a `<vlan_id>` is modified, and:
* removes the vlan from a port if the number of `<enabling_token>` = 0
* adds the vlan to a port if the number of `<enabling_token>` >= 1

To give a concrete example, our ML2 mechanism driver currently uses OpenStack VM UUIDs as `<enabling_token>` nodes. This way it indicates which VMs are using a given VLAN on a given server port. Also, if no VMs are using the VLAN/port combination, the corresponding enabling_token will be removed from etcd and the VLAN from the port.

*(In future releases our ML2 mechanism driver will use an OpenStack VM's interfaces' MAC addresses as enabling tokens)*

## Example Actions
etcd can be interacted with using a range of interfaces.
The tested are:
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

## Additional Resources
* [*etcd_connector* Repository][etcd_connector]
* [etcd Documentation][etcd_docs]
* [etcd Github][etcd_gh]
* [ML2 Plugin Extension Repository][ml2]

[etcd_docs]: https://github.com/coreos/etcd/blob/master/Documentation/docs.md (etcd Documentation)
[etcd_gh]: https://github.com/coreos/etcd (etcd Github)
[etcd_connector]: https://gitlab.bisdn.de/basebox/etcd_connector (*etcd_connector* repository)
[ml2]: https://gitlab.bisdn.de/basebox/car_ml2_mecha_driver (ML2 Plugin Extension Repository)
