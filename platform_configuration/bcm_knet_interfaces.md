---
title: Broadcom KNET network interfaces
parent: Platform Configuration
nav_order: 6
---

Broadcom KNET network interfaces ("bcm-knet") are an alternative for the "tun" interface type for the linux representation of the switch ports. They directly forward the packets in the kernel to and from the switch, reducing overhead and improving throughput and latency when communicating from the switch itself.

Due to the nature of the implementation, these can only be used when running `baseboxd` on the switch itself. When running `baseboxd` off-switch, only the tap interfaces are available.

## Checking currently used network interface implementation

To check which network interface implementation is used, check the output of

```
ethtool -i port1
```

If the default Broadcom KNET network interface implementation is used, it will show

```
driver: bcm-knet
```

If the old tap interface implementation is used, it will show

```
driver: tun
```

### Disabling use of Broadcom KNET network interfaces

To disable the use of Broadcom KNET network interfaces and switch to tap interfaces, edit `/etc/default/baseboxd` and change

```
# Use KNET interfaces:
# FLAGS_use_knet=true
```

to

```
# Use KNET interfaces:
FLAGS_use_knet=false
```

and reboot the switch.

### Enabling use of Broadcom KNET network interfaces

To enable the use of Broadcom KNET network interfaces again, edit `/etc/default/baseboxd` and change

```
# Use KNET interfaces:
FLAGS_use_knet=false
```

to

```
# Use KNET interfaces:
FLAGS_use_knet=true
```

and reboot the switch.

### Configuring packets being marked as forwarding offloaded to hardware

When using KNET interfaces, packets are by default marked as forwarding offloaded to hardware to avoid linux duplicating packages on bridges.

When linux receives packets on an interface that is part of a bridge, it will forward them according to the bridging rules. This can lead to duplicated packets if the switch ASIC already forwarded them and sent a copy to the controller, e.g. for ARP traffic. By marking them as as forwarding offloaded it tells linux that they were already forwarded or flooded in hardware, and it does not need to do so itself.

**Note**: Currently all packets are marked as offloaded, regardless whether they were actually forwarded or flooded. If there are ACL rules redirecting packets to the controller that should be forwarded or flooded as well, being marked as offloaded prevents the packets from being forwarded or flooded correctly. In this case, disabling this option will allow proper forwarding and flooding.

To disable packets being marked as forwarding being offloaded edit `/etc/default/baseboxd` and set the option to `false`:

```
# Mark switched packets as offloaded:
FLAGS_mark_fwd_offload=false
```

and reboot the switch.
