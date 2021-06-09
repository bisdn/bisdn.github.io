---
title: Port Mirroring
parent: Platform Configuration
nav_order: 1
---

## Port mirroring

BISDN Linux supports the configuration of mirror ports. Mirrored ports replicate incoming/outgoing traffic, according to their configuration flag. The supported port mirroring flags are the following:

* `OFDPA_MIRROR_PORT_TYPE_INGRESS`: Only ingress traffic is mirrored
* `OFDPA_MIRROR_PORT_TYPE_EGRESS`: Only egress traffic is mirrored
* `OFDPA_MIRROR_PORT_TYPE_INGRESS_EGRESS`: Both ingress and egress traffic are mirrored

Please note that when mirroring ports with different maximum link speeds (e.g. a 10G
port mirrored to a 1G port), the highest common link speed (1G for the
aforementioned example) will be used for both ports.
{: .label .label-yellow }

The following example shows how to mirror ingress traffic from port 2 to port 8 in a switch, as shown in this figure:

![Port mirroring example](/assets/img/port_mirror_example.png)

### Adding mirror ports

Add port 8 as a mirror port:

```
grpc_cli call <IP>:50051 ofdpaMirrorPortCreate "port_num: 8"
```

Where `<IP>` is the IP of the whitebox switch (`localhost` when logged in locally to the switch).

Then, set port 2 as the mirror source and configure the port type to only mirror ingress traffic:

```
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 8 }, mirror_src_port_num: { port_num: 2 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS}"
```

### Verifying mirror port configuration 

See the mirror port configuration by running the following command on the whitebox switch:

```
client_mirror_port_dump
```

Mirrored traffic cannot be captured on the switch mirror ports. Hence, to verify that traffic is being mirrored, we need to capture traffic on the server port that is connected to the mirror switch port. Within the example from the figure, the following command should be executed on `server2`:

```
sudo tcpdump -i eno8
```

### Deleting mirror ports

The port mirror configuration can be deleted with the following commands:

```
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 8 }, mirror_src_port_num: { port_num: 2 }"
grpc_cli call <IP>:50051 ofdpaMirrorPortDelete "port_num: 8"
```

### Port mirroring of bonded interfaces

Port mirroring works with physical ports, not logical ports, so to mirror the full traffic of a bonded interface all the individual bond members need to be mirrored. These can be either mirrored 1:1 to additional ports, or all bond members mirrored to one port.
