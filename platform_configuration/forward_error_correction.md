---
title: Forward Error Correction (FEC)
parent: Platform Configuration
nav_order: 3
---

### Enabling Forward Error Correction (FEC) on a port

By default Broadcom switches do not enable any Forward Error Correction on ports.

To enable Forward Error Correction use the [client_drivshell](tools/ofdpa_client_tools.md#client_drivshell) tool.

There are multiple algorithms supported:

* Base-R, defined in IEEE 802.3, clause 74.
* Reed-Solomon (RS) for 100G ports, defined in IEEE 802.3, clause 91.
* Reed-Solomon (RS) for 25G ports, defined in IEEE 802.3, clause 108.

The configuration uses the clause numbers to reference the different modes.

E.g., to enable RS for 100G on the first port, simply run:

```
client_drivshell phy control 1 cl91=true
```

To check the current configuration, call it without setting any modes:

```
client_drivshell phy control 1
Current PHY control settings of ce0 ->
Preemphasis              = 0x14410a
DriverCurrent            = 0xffffffff
DFE ENable               = True
LP DFE ENable            = True
BR DFE ENable            = False
LinkTraining Enable      = False
Interface                = 0x3e
CL74                     = False
CL91                     = True
CL108                    = False
```

This shows that the port has the FEC mode clause 91 or Reed-Solomon for 100G ports enabled.

### Disabling Forward Error Correction (FEC)

FEC mode none is configured as all FEC modes being disabled. So to disable forward error correction, set the currently enabled mode to false.

E.g. if the current FEC mode on port 1 is RS over 100G, call:

```
client_drivshell phy control 1 cl91=false
```

### Persistent Forward Error Correction (FEC) configuration

Switch port configuration can be persisted across restarts. In order to enable RS over 100G for the ports 1 and 2 one would run

```
client_drivshell phy control 1 cl91=true
client_drivshell phy control 2 cl91=true
```

To make the commands persist one would add the following lines to the file /etc/ofdpa/rc.soc

```
phy control 1 cl91=true
phy control 2 cl91=true
exit
```

Note the absence of client_drivshell and the single exit statement at the end.

### Forward Error Correction (FEC) and bonded interfaces

Forward Error Correction is a property of physical ports, while bond interfaces are logical ports. So any FEC configuration needs to be set for the individual bond members.
