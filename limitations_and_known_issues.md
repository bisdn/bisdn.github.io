---
title: Limitations and known issues
nav_order: 10
---

# Limitations

## Some Forward Error Correction (FEC) modes may be unavailable

Depending on the switch ASIC used, some FEC modes may be unavailable to configure:

- Helix 4 based switches like Accton AS4610 only support Base-R on their 20G ports.
- Trident II+ based switches like the Agema AG7648 only support Base-R.
- Tomahawk based switches like the Agema AG5648 (non V1) only support Base-R on
  25G ports. RS support is limited to 100G ports. Tomahawk+ based switches like
  the Agema AG5648V1 does not have this limitation.

## No VxLAN support on Accton AS4610

The Broadcom Switch ASIC used in Accton AS4610 does not support VxLAN.

## Celestica Questone 2A fans spinning at 100%

Please ensure that both PSUs are connected and have power. The switch will fall
back to a fail-safe mode with all fans spinning at 100% if only one of the PSUs
is available.

## Table size differences

There might be discrepancies in the maximum number of entries in the unicast
routing table (30) announced by
[of-dpa](https://github.com/Broadcom-Switch/of-dpa) and how many it accepts.

The Agema AG7648 switch announces a maximum of 32k entries for the unicast
routing table(30) and [of-dpa](https://github.com/Broadcom-Switch/of-dpa) takes
16k host routes and 16k network routes.

## Linux namespaces

baseboxd is not compatible with [Linux
namespaces](http://man7.org/linux/man-pages/man8/ip-netns.8.html). Moving
baseboxd’s interfaces to a namespace will duplicate them.

## Upgrade of BISDN Linux via onie-bisdn-upgrade

The script onie-bisdn-upgrade allows to use static IP configuration instead of
DHCP. However, using the current ONIE installer, there is no route set towards
the gateway, so images outside the configured network or, when using the
“current” option, outside the switch management network (‘enp0s20f0’) can not
be pulled and installed automatically.

## Enabling auto-negotiation on ports may not work as expected

Depending on the switch and the link partner, we have observed the following
behaviors:

- Intel X552 10 GbE SFP+ network cards do not support auto-negotiation. This
  causes the link to take more than 30 seconds to come up when the port is set
  to auto-negotiation.

- The 10G ports on
  [AS4610](https://www.edge-core.com/productsList.php?cls=1&cls2=9&cls3=46)
  only support advertising 1G, so the speed will be limited to 1G regardless of
  the link partner's ability.

- There is an issue in the Broadcom SDK version 6.5.21 and following, which
  affects all BISDN Linux releases after 3.7, where the 10G ports on
  [AS4610](https://www.edge-core.com/productsList.php?cls=1&cls2=9&cls3=46) will
  not transfer packets when auto-negotiating down to 1G after being configured
  for 10G. Forcing the speed to 1G with disabled auto-negotiation avoids this
  issue.

- The 25G ports on Agema AG5648 do not support simultaneous detection of 1G
  with SGMII and 1G with KX, and will treat it as 1G with KX. If you use 1G SFP
  modules, configure the port to a fixed speed with 1G to work around this.

In all of these cases forcing the port on the switch to the desired speed works
as expected.

# Open issues

## Using VLAN 1 on a bridge and ports outside of a bridge may lead to packet leakage

Affected versions: 3.0 - current

Internally, baseboxd uses VLAN 1 for untagged traffic on ports not part of a
bridge. If using VLAN 1 on a bridge at the same time, some packets received on
those ports may get flooded to ports that are part of the bridge regardless.
This may cause connected switches to learn MAC addresses on the wrong ports or
unexpected loops.

With BISDN Linux 5.1.1 we added a new baseboxd option to change the internal
VLAN for unbridged ports. Please use
[FLAGS\_port\_untagged\_vid](getting_started/configure_baseboxd.md#setup-baseboxd)
to move it to an unused VLAN to avoid this issue.

## Ports default to no FEC even if the SFP module type inserted requires FEC

Affected versions: 3.0 - current

Currently ports will always default to no FEC regardless of the SFP module
used. If the remote side follows the requirement, this can prevent the link
from being established. In that case [configure the FEC mode manually](platform_configuration/forward_error_correction.md).

## No support for VXLAN on bonded interfaces

Affected versions: 3.5 - current

Currently VXLAN is not supported on bonded interfaces.

## Missing routes for EIGRP with flapping ports

Affected versions: 3.0 - current

As documented in the currently open upstream FRR issue
[#7299](https://github.com/FRRouting/frr/issues/7299), some routes may get
dropped or are not correctly received when ports are flapping during EIGRP
session establishment. For now, we recommend the workaround of restarting FRR
after all ports are up if this behavior is observed.

## Accton-AS4630-54PE: Link speed setting for interfaces connected with optical modules

Affected versions: 4.4 - current

The Accton AS4630-54PE platform may not properly establish a link when using
optical 100G modules. As a workaround, add the following configuration into
`/etc/ofdpa/rc.soc`.

```
phy control 53-54 preemphasis=0x124106
```

# Resolved issues

## Accton-AS4630-54PE: LEDs for the SFP interfaces signal in white colour

Affected versions: 4.4 - 4.6

In releases 4.4 to 4.6 the Accton AS4630-54PE platform LEDs for the SFP
interfaces are always stuck on white. In release 4.6.1 a fix was implemented,
and the SFP LEDs now light up correctly.

## Socket receive buffer size causes baseboxd to miss netlink events

Affected versions: 3.0 - 4.5

BISDN Linux increases `net.core.rmem_default` while leaving `net.core.rmem_max`
at the default value which is lower than the new `net.core.rmem_default`.
Because baseboxd creates its netlink read buffer based on the max value, a
large burst of netlink events may result in netlink messages being lost, with
baseboxd failing to fully synchronize the ASIC state with the kernel state.
The solution is to add the line `net.core.rmem_max=8388608` to `/etc/sysctl.d/20-network-io.conf`.

## MAC addresses of BCM KNET interfaces change on every boot

Affected versions: 4.5

In release 4.5 the MAC addresses on BCM KNET interfaces are randomly assigned
with an OUI of 02:10:18. Due to the fixed OUI systemd does not recognize the
address as randomized, and does not replace it with a stable MAC address.

Starting with release 4.6 correctly tagged random mac addresses are assigned,
which systemd now replaces with stable MAC addresses.

## BCM KNET interfaces stay after stopping baseboxd

Affected versions: 4.5

In release 4.5, due to the way BCM KNET interface control is implemented,
baseboxd fails to remove them when stopping. If you need to disable baseboxd,
please reboot the switch to reset the state afterwards.

In release 4.6 a new helper script for automatically removing BCM KNET
interfaces was added and is run when stopping baseboxd.

## No support for STP on bonded interfaces

Affected versions: 3.5 - 4.4

In releases prior to 4.5, the spanning tree protocols STP, RSTP and MSTP were
not supported on bonded interfaces.

## DHCP packets not forwarded correctly

Affected versions: 3.0 - 4.0

In BISDN Linux prior to the release 4.1, switches would sometimes stop
forwarding DHCP packets correctly due to an issue in handling multicast
subscriptions within OF-DPA. The only known workaround (starting with BISDN
Linux v4.0) is to [disable IGMP/MLD Snooping](network_configuration/igmpmldsnooping.md#enablingdisablingigmpmldsnooping).
To avoid the issue completely, we recommend upgrading to release 4.1 or higher.

## Celestica Questone 2A port LEDs do not light up

Affected versions: 4.0

In BISDN Linux prior to the release 4.1 the LEDs on Celestica Questone 2A ports
do not light up when a link is established.

## Agema-5648 PCIe Bus error

Affected versions: 3.0 - 3.5.1

The driver for the PCI bus may report an error leading to the controller not
receiving any traffic and causing the platform to completely stop working until
restarted. This is a sporadic bug and can be verified by running dmesg where
the following logs are available to confirm the presence of the error.

```
[...] pcieport 0000:00:01.0: AER: Uncorrected (Non-Fatal) error received: 0000:01:00.0
[...] linux-kernel-bde 0000:01:00.0: AER: PCIe Bus Error: severity=Uncorrected (Non-Fatal), type=Transaction Layer, (Requester ID)
[...] linux-kernel-bde 0000:01:00.0: AER:   device [14e4:b967] error status/mask=00004000/00000000
[...] linux-kernel-bde 0000:01:00.0: AER:    [14] CmpltTO                (First)
[...] pcieport 0000:00:01.0: AER: Device recovery successful
```
The message `AER: Device recovery successful` shown above is misleading, since
the Error can only be resolved by fully rebooting the switch itself.

## Ports connected during boot may sometimes show as having no carrier in Linux

Affected versions: 3.0 - 3.7.2

All releases of BISDN Linux prior to version 3.7.3 suffer from an issue where
the port state might end up out of sync.

This is caused by a race in OF-DPA, where OF-DPA first initializes ports with
their current state, and only then registers the linkscan handler, which
is responsible for updating OF-DPA's port state. This creates a window where
OF-DPA will miss any physical link state changes happening.

Any port state changes happening between the initial read out and the
successful registration of the handler will be missed.

The port sync issue may be identified by the link's inability to set a port up
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

## Accton-AS4630-54PE: PoE driver does not read from the correct i2c path

Affected versions: 4.4 - 4.4.1

The `poectl` utility uses a wrong path to access the poe controller device.

To work around this, edit `/usr/sbin/poectl` and change

```
systempath=/sys/kernel/debug/i2c-16-0020
```
to

```
systempath=/sys/kernel/debug/16-0020
```
