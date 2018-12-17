# Workflows

## Accessing the system

Operations with the Basebox environment require you to access the servers and switches, in order to run commands on these devices. The most common way for accessing Linux devices is using the 
``ssh`` command, which allows for securely entering a shell in a remote device. From one machine connected to the management network, you can execute the command:

```
ssh <username>@<address of the SDN controller>
```

When the prompt for the password shows up, input the correct password that was provided to you in the document that accompanies 
the Basebox machines. 

After sucessfully logging in to the controller, you can interact with the Basebox setup. 

## Integration into Linux

### systemd

One of the most basic operations that you can make is checking the health of the services included with the Basebox setup. You
can do this via the command:

```
systemctl status <service name>
```

Currently, the services names are:

```
baseboxd
cawr (if used)
etcd_connector
basebox-api
basebox-gui
```

The commands to stop/start a service is similar.

If any service is not running properly, you can also try a restart via:

```
systemctl restart <service name>
```

Another useful feature for debugging the Basebox setup is looking at the logs from the components. By default, all the Basebox services log their output to journal, and this
can be accessed via

```
journalctl -u <service name>
```

## Network Operations

If all of the services are correctly started and running, the ports will be configured on your SDN controller. You can verify the
state of your ports by executing the command:

```
ip link show
```

In the output following this command, you can see the state of baseboxd's configured ports, that have the structure ``port<identifier>``.
This identifier can either be a number, in the case of the single switch Basebox setup, or a 6 letter and number combination, in
the case where CAWR is running. 

Creating a bridge on the Linux environment is done via:

```
ip link add <bridgename> type bridge
ip link set <bridgename> type bridge vlan_filtering 1
ip link set <bridgename> up
```

Adding ports to a bridge is done via:

```
ip link set port<identifier> master <bridgename>
ip link set port<identifier> master <bridgename>
```

And removing ports from the bridge <bridgename>,

```
ip link set port<identifier> nomaster
ip link set port<identifier> nomaster
```

Adding VLANs to bridge port is 

```
bridge vlan add vid 2 dev port<identifier>
bridge vlan add vid 2-4 dev port<identifier>
```

Removing VLANs from bridge port:

```
bridge vlan del vid 2 dev port<identifier>
bridge vlan del vid 2-4 dev port<identifier>
```

Adding and deleting the Layer 3 addresses to interfaces can be done via:

```
ip address add <IP address> dev port<identifier>
ip address delete <IP address> dev port<identifier>
```

### etcd_connector

``etcd_connector`` allows you to skip manually executing these commands by automatically configuring this information based on entries on the etcd database. ``etcd_connector`` will manage the files that
systemd-networkd uses to configure interfaces. Executing the commands linked [here][etcd_conn] will manage these files, thus providing an easier API for interface configuration.

An alternate step for IP address and VLAN management can be done via the GUI, which you can find further information [here][gui].

### gRPC interface

We provide you with a gRPC interface that enables to interact with parts of the [OF-DPA API][ofdpa_api] that are not available via OpenFlow. A cli-tool named `grpc-cli` is available that can be used to interact with our gRPC endpoint.

This example shows how to create a VxLAN tunnel endpoint (see the official API [here](http://broadcom-switch.github.io/of-dpa/doc/html/group__GLOFDPAAPI.html#ga713ed66d831800bede08b3cd985ead49)):

```
grpc_cli call localhost:50051 ofdpaTunnelTenantCreate "tunnel_id: 0x00001, config: { proto: OFDPA_TUNNEL_PROTO_VXLAN, virtual_network_id: 33}"
```

To have this call any effect on the switch, make sure that the `ofdpa-grpc` component is active.

## Additional resources
* [iproute2][iproute2]
* [systemd-networkd][networkd]
* [OF-DPA API] [ofdpa_api]
**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[etcd_conn]: ../api/api_definition.html
[gui]: ../gui/introduction.html
[iproute2]: https://wiki.linuxfoundation.org/networking/iproute2 (iproute2 Wiki)
[networkd]: https://www.freedesktop.org/software/systemd/man/systemd.network.html (Systemd-networkd man page)
[ofdpa_api]: http://broadcom-switch.github.io/of-dpa/doc/html/index.html
