# API Definition

## Introduction
The Basebox configuration information is stored in a highly available [etcd][etcd_gh] cluster.
The access to this etcd cluster is open to the Basebox users and effectively provides an API for configuring Basebox.
Using etcd as a means of configuration allows us to reliably store the configuration information, track the configuration changes and react to them.
It stores information in a directory-like structure, and each 'directory' and 'leaf' data node holds a modification index.
The *[etcd connector][etcd_connector]* uses this index to track changes to the data strture, thus allowing it to react to changes in as they happen.

For more specific information on etcd data structure and reading/writing mechanisms please refer to [etcd documentation][etcd_docs].

## Configuration data structure
Basebox enforces that the data in etcd is stored in the following format:

```text
/directory structure/

   prefix    directory       directory   key(file)   value(file)
     |           |               |           |           |
     v           v               v           v           v
/<prefix>/<physical_port_id>/<vlan_id>/<enabling_token> ''

```
### physical_port_id
The etcd directory in `/<prefix>` stores a list of directories, labeled with the names of the physical ports: `<physical_port_id>`. Each physical port ID is a unique value, only one entry per physical port can exist.

### vlan_id
Each physical port directory can hold zero or more directories, labeled with the names of the vlan IDs: `<vlan_id>`. Since we can have the same vlan ID enabled on multiple ports, it is a value unique to each `<physical_port_id>` directory but not globally unique.

### enabling_token
Each vlan ID directory can hold zero or more files (leaf nodes), labeled: `<enabling_token>`. The contents of the node are always `''` (empty). Since we can have the same enabling_token connected to multiple ports and multiple vlans, it is a value unique to each `<vlan_id>` directory but not neceserily globally unique.

### Configuration triggers
A physical port can exist in the configuration on its own, similarily a pair: a port and a vlan can co-exist in the etcd store without any leaf nodes. However, only if you have all three values present in the format shown by this document does Basebox configure the vlans on the switch ports.

```text
/ etcd directory structure example /

/basebox/ports/
              ├── physical_port_1
              │   └── VID_3                 <- / vlan enabled /
              │        └── enabling_token_2
              ├── physical_port_2
              │   └── VID_1                 <- / vlan disabled /
              ├── physical_port_3
              │   └── VID_4                 <- / vlan enabled /
              │        └── enabling_token_2
              │        └── enabling_token_3
              └── physical_port_4
                  └── VID_2                 <- / vlan disabled /
```

The most important events, triggering configuration changes of the vlan configuration on the switches, is the addition and removal of `<enabling_token>` nodes to and from vlan_id directories. Currently, the *etcd connector* checkes for the number `<enabling_token>` nodes in the `<vlan_id>` directory every time a `<vlan_id>` is modified, and:
* removes the vlan from a port if the number of `<enabling_token>` = 0
* adds the vlan to a port if the number of `<enabling_token>` >= 1

To give a concrete example, our ML2 mechanism driver currently uses OpenStack VM UUIDs as `<enabling_token>` nodes. This way it indicates which VMs use using a given VLAN on a given server port. Also, if no VMs are using the VLAN/port combination, the coresponding enabling_token will be removed from etcd and the VLAN from the port.

*(In future releases our ML2 mechanism driver will use an OpenStack VM's interfaces' MAC addresses as enabling tokens)*

## Actions
etcd can be interacted with using a range of interfaces.
The tested are:
* etcdctl command line tool
* REST interface
* etcd-python module

### Add physical_port_id
etcdctl:
```shell
etcdctl mkdir /<physical_port_id>’
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id> -XPUT -d dir=true
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.write('/<physical_port_id>', None, dir=True)
```

### Add vlan_id
etcdctl:
```shell
etcdctl mkdir /<physical_port_id>/<vlan_id>’
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id>/<vlan_id> -XPUT -d dir=true
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.write('/<physical_port_id>/<vlan_id>', None, dir=True)
```

### Add enabling_token
etcdctl:
```shell
etcdctl set /<physical_port_id>/<vlan_id>/<enabling_token> ''
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id>/<vlan_id>/<enabling_token> -XPUT -d value=""
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.write('/<physical_port_id>/<vlan_id>/<enabling_token>', '')
```

### Remove physical_port_id
etcdctl:
```shell
etcdctl rmdir /<physical_port_id>
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id>?dir=true -XDELETE
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.delete('/<physical_port_id>', recursive=True)
```

### Remove vlan_id
etcdctl:
```shell
etcdctl rmdir /<physical_port_id>/<vlan_id>
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id>/<vlan_id>?dir=true -XDELETE
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.delete('/<physical_port_id/<vlan_id>', recursive=True)
```

### Remove enabling_token
etcdctl:
```shell
etcdctl rm /<physical_port_id>/<vlan_id>/<enabling_token>
```

REST call:
```shell
curl http://<etcd-host>:<etcd-port>/v2/keys/<physical_port_id>/<vlan_id>/<enabling_token> -XDELETE
```

Python module function call:
```python
import etcd
client = etcd.Client(host='<etcd-host>', port='<etcd-port>')
client.delete('/<physical_port_id/<vlan_id>/<enabling_token>')
```

## Additional Resources
* [*etcd_connector* Repository][etcd_connector]
* [etcd Documentation][etcd_docs]
* [etcd Github][etcd_gh]
* [ML2 Plugin Extension Repository][ml2]

[etcd_docs]: https://github.com/coreos/etcd/blob/master/Documentation/docs.md (etcd Documentation)
[etcd_gh]: https://github.com/coreos/etcd (etcd Github)
[etcd_connector]: https://gitlab.bisdn.de/basebox/vlantranslate (*etcd_connector* repository)
[ml2]: https://gitlab.bisdn.de/basebox/car_ml2_mecha_driver (ML2 Plugin Extension Repository)
