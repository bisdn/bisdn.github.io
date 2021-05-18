---
title: Limitations
nav_order: 8
---

# Limitations

## Agema-5648 PCIe Bus error

**A workaround preventing the issue has been implemented in BISDN Linux 3.5.2.**

The driver for the PCI bus may report an error leading to the controller not receiving any traffic and causing the platform to completely stop working until restarted. This is a sporadic bug and can be verified by running dmesg where the following logs are available to confirm the presence of the error.

```
[...] pcieport 0000:00:01.0: AER: Uncorrected (Non-Fatal) error received: 0000:01:00.0
[...] linux-kernel-bde 0000:01:00.0: AER: PCIe Bus Error: severity=Uncorrected (Non-Fatal), type=Transaction Layer, (Requester ID)
[...] linux-kernel-bde 0000:01:00.0: AER:   device [14e4:b967] error status/mask=00004000/00000000
[...] linux-kernel-bde 0000:01:00.0: AER:    [14] CmpltTO                (First)
[...] pcieport 0000:00:01.0: AER: Device recovery successful
```
The message `AER: Device recovery successful` shown above is misleading, since the Error can only be resolved by fully rebooting the switch itself.
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

- There is an issue in the current Broadcom SDK where the 10G ports on [AS4610](https://www.edge-core.com/productsList.php?cls=1&cls2=9&cls3=46) will not transfer packets when autonegotiating down to 1G after being configured for 10G. Forcing the speed to 1G with disabled autonegotiation avoids this issue.

- The 25G ports on [AG5648](https://agema.deltaww.com/product-info.php?id=41) do not support simultaneous detection of 1G with SGMII and 1G with KX, and will treatit as 1G with KX. If you use 1G SFP modules, configure the port to a fixed speed with 1G to work around this.

In all of these cases forcing the port on the switch to the desired speed works as expected.
