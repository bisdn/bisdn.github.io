---
title: Power Over Ethernet (PoE)
parent: Platform Configuration
nav_order: 5
---

**WARNING**: PoE is currently an experimental feature.
{: .label .label-red }

# Power Over Ethernet (PoE)

## Introduction

Power over Ethernet (PoE) is a technique that allows providing electric power and data over an ethernet cable. The original PoE standard (IEEE 802.3af) supplied up to 15.4 W per port, but the revision of the standard (802.3at) increased it to 25.5 W, and the newest revision 802.3bt-2018 increased the maximum to 71 W by using all four pairs.

Two types of devices supporting PoE are considered regarding PoE capabilities: the *Power Sourcing Equipment (PSE)*, which are the devices capable of providing power on the cable; and the *Powered Device (PD)*, which are devices that consume energy provided by PoE. Some BISDN Linux supported switches can act as a Power Sourcing Equipment (please refer to the platform specification provided by your vendor).  

## Configuration

BISDN Linux comes with the command line utility `poectl`, which provides a simple and convenient way to configure PoE.

### Usage

```
:~$ poectl -h
poectl for enable, disable, status and measurements of PoE ports
 
 Usage:  poectl [OPTIONS] PORT | all
 
 OPTIONS:
  -h   help
  -v   version
  -e   enable PoE
  -d   disable PoE
  -s   PoE status
  -mV  PoE voltage
  -mC  PoE current
  -mT  PoE temperature
  -mP  PoE power
```

### Examples

To enable PoE on a port run the following command:

```
:~$ poectl -e port2
```

To disable PoE on a port:

```
:~$ poectl -d port2
```

To check the voltage on a certain port:

```
:~$ poectl -mV port2
PoE voltage status port2: 54.27V
```
