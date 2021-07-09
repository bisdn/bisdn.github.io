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

- The 25G ports on [AG5648](https://agema.deltaww.com/product-info.php?id=41) only support advertising up to 10G, so the speed will be limited to 10G regardless of the link partner's ability.

In all of these cases forcing the port on the switch to the desired speed works as expected.

## Missing routes for EIGRP with flapping ports

As documented in the currently open upstream FRR issue [#7299](https://github.com/FRRouting/frr/issues/7299), some routes may get dropped or are not correctly received when ports are flapping during EIGRP session establishment. For now, we recommend the workaround of restarting FRR after all ports are up if this behavior is observed.

## Ports connected during boot may sometimes show as having no carrier in Linux

All releases of BISDN Linux prior to version 3.7.3 suffer from an issue where
the port state might end up out of sync.

This is caused by a race in OF-DPA, where OF-DPA first initializes ports with
their current state, and only then registers the linkscan handler, which
is responsible for updating OF-DPA's port state. This creates a window where
OF-DPA will miss any physical link state changes happening.

Any port state changes happening between the initial read out and the
successful registration of the handler will be missed.

The port sync issue may be identified by the link inability to set a port up
even though the port is connected. Using port2 as an example we run

```
ip link set port2 up
ip link show port2

port2: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
```

Which shows ``NO-CARRIER`` and ``state DOWN``. You can resolve the issue by
using the OF-DPA api to first disable and then enable the port again.

``client_drivshell port 2 Enable=false``
``client_drivshell port 2 Enable=true``
