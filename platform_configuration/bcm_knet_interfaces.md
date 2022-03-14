---
title: Broadcom KNET network interfaces
parent: Platform Configuration
nav_order: 6
---

Broadcom KNET network interfaces ("bcm-knet") are an alternative for the "tun" interface type for the linux representation of the switch ports. They directly forward the packets in the kernel to and from the switch, reducing overhead and improving throughput and latency when communicating from the switch itself.

Due to the nature of the implementation, these can only be used when running `baseboxd` on the switch itself. When running `baseboxd` off-switch, only the tap interfaces are available.

**Note**: The Broadcom KNET network interfaces are still an experimental feature, and may not always work as expected. See [Limitations and known issues](../limitations_and_known_issues.md) for details.
{: .label .label-yellow }

## Checking currently used network interface implementation

To check which network interface implementation is used, check the output of

```
ethtool -i port1
```

If the default tap interface implementation is used, it will show

```
driver: tun
```

If the new Broadcom KNET network interface implementation is used, it will show

```
driver: bcm-knet
```

### Enabling use of Broadcom KNET network interfaces

To enable the use of Broadcom KNET network interfaces, edit `/etc/default/baseboxd` and change

```
# Use KNET interfaces (experimental):
# FLAGS_use_knet=false
```

to

```
# Use KNET interfaces (experimental):
FLAGS_use_knet=true
```

and reboot the switch.

### Disabling use of Broadcom KNET network interfaces

To disable the use of Broadcom KNET network interfaces and switch back to tap interfaces again, edit `/etc/default/baseboxd` and change

```
# Use KNET interfaces (experimental):
FLAGS_use_knet=true
```

to

```
# Use KNET interfaces (experimental):
FLAGS_use_knet=false
```

and reboot the switch.
