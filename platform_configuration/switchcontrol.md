---
title: SwitchControl
parent: Platform Configuration
nav_order: 4
---

# TTL controls

BISDN Linux has a default configuration file under `/etc/ofdpa/rc.soc` controlling both the Broadcom SDK and OF-DPA.

To enable routing packets with TTL=1 to CPU by default, the file contains the following setting:

```
SwitchControl L3UcastTtl1ToCpu=1
```

The following command will activate the same behaviour on the switch in a non-persistent way:

```
client_drivshell SwitchControl L3UcastTtl1ToCpu=1
```

To print the currently set value, you can run:

```
client_drivshell SwitchControl L3UcastTtl1ToCpu
```
