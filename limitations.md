---
title: Limitations
nav_order: 8
---

# Limitations

## Agema-5648 PCIe Bus error

The driver for the PCI bus crashes and the controller does not receive any traffic, which will cause the platform to completely stop working until restarted.
By running dmesg, the following logs are available to confirm the presence of the error.

```
[11411.162858] pcieport 0000:00:01.0: AER: Uncorrected (Non-Fatal) error received: 0000:01:00.0
[11411.172328] linux-kernel-bde 0000:01:00.0: AER: PCIe Bus Error: severity=Uncorrected (Non-Fatal), type=Transaction Layer, (Requester ID)
[11411.186059] linux-kernel-bde 0000:01:00.0: AER:   device [14e4:b967] error status/mask=00004000/00000000
[11411.196670] linux-kernel-bde 0000:01:00.0: AER:    [14] CmpltTO                (First)
[11411.205600] pcieport 0000:00:01.0: AER: Device recovery successful
```

## Table size differences

There might be discrepancies in the maximum number of entries in the unicast routing table (30) announced by [of-dpa](https://github.com/Broadcom-Switch/of-dpa) and how many it accepts.

The [AG7648](https://agema.deltaww.com/product-info.php?id=29) switch announces a maximum of 32k entries for the unicast routing table(30) and [of-dpa](https://github.com/Broadcom-Switch/of-dpa) takes 16k host routes and 16k network routes.

## Linux namespaces

baseboxd is not compatible with [Linux namespaces](http://man7.org/linux/man-pages/man8/ip-netns.8.html). Moving basebox’s interfaces to a namespace will duplicate them.

## Upgrade of BISDN Linux via onie-bisdn-upgrade

The script onie-bisdn-upgrade allows to use static IP configuration instead of DHCP. However, using the current ONIE installer, there is no route set towards the gateway, so images outside the configured network or, when using the “current” option, outside the switch management network (‘enp0s20f0’) can not be pulled and installed automatically.


## Enabling auto-negotiation on ports may not work as expected

Depending on the switch and the link partner, we have observed the following behaviors:

- Intel X552 10 GbE SFP+ network cards do not support auto-negotiation. This causes the link to take more than 30 seconds to come up when the port is set to autonegotiation.

- The 10G ports on [AS4610](https://www.edge-core.com/productsList.php?cls=1&cls2=9&cls3=46) only support advertising 1G, so the speed will be limited to 1G regardless of the link partner's ability.

- The 25G ports on [AG5648](https://agema.deltaww.com/product-info.php?id=41) only support advertising up to 10G, so the speed will be limited to 10G regardless of the link partner's ability.

In all of these cases forcing the port on the switch to the desired speed works as expected.
