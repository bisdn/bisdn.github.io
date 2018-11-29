# Quick start to configure L2 and L3 forwarding

This section shows examples that help you to configure bridging and routing using baseboxd. For a more automated approach find the respective [configuration scripts][bbd-examples] on the baseboxd github.

## Configure L2 switch (bridging)

This example shows how to configure a simple L2 switch using baseboxd.

Assume the following physical topology:

```
# +--------+       +------------+
# |  Host  |       |   Switch   |
# +--------+       +------------+
#    eth1  -------->  port1
#    eth2  -------->  port2
```

Using the configuration below you can add both ports to a bridge (here: swbridge) and create the following logical connections:

```
#  port1 \
#         > swbridge
#  port2 /
```

### Configure bridge on the controller host

1. Create a VLAN-filtering bridge (here: swbridge) on the machine where baseboxd is running (remote or local controller):

```
ip link add name swbridge type bridge vlan_filtering 1
ip link set swbridge up
```

2. Add both ports to the bridge

Assuming the hosts are connected to port1 and port2 on the switch, do the following:

```
ip link set port1 master swbridge
ip link set port1 up

ip link set port2 master swbridge
ip link set port2 up
```

3. Add VLAN IDs to the ports

The enable bridging on certain VIDs just add them to the ports:

```
bridge vlan add vid 2 dev port1
bridge vlan add vid 2 dev port2
```

### Setup the hosts

Follow the instructions of your operating system on the host. Make sure that the ports on the host are in the same VLANs that are configured on the controller ports.

## Configure routing

Routing is even easier to setup. Just configure networks on ports of your choice.

```
ip address add 10.20.30.1/24 dev port1
```

Then add the corresponding addresses and routes to the connected hosts and that's it. For additional information please have a look at the (examples)[bbd-examples].


## Additional resources
* [baseboxd GitHub repository][baseboxd]
* [Configuration scripts on GitHub][bbd-examples]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[baseboxd]: https://github.com/basebox (baseboxd on github)
[bbd-examples]: https://github.com/bisdn/basebox/tree/master/examples (baseboxd examples on github)
