---
title: Power Over Ethernet (PoE)
parent: Platform Configuration
nav_order: 5
---

**WARNING**: PoE is currently an experimental feature.
{: .label .label-red }

# Power Over Ethernet (PoE)

## Introduction

Power over Ethernet (PoE) is a technique that allows providing electric power and data over an Ethernet cable. The original PoE standard (IEEE 802.3af) supplies up to 15.4 W per port, and was increased to 25.5 W with a revision to the standard (802.3at).

Two types of devices supporting PoE are considered regarding PoE capabilities: the *Power Sourcing Equipment (PSE)* which are the devices capable of providing power on the cable; and the *Powered Device (PD)* are devices that consume energy provided by PoE. Some BISDN Linux supported switches can act as a Power Sourcing Equipment.  

## Configuration

BISDN Linux comes with an application `poectl` that allows for PoE configuration.

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

Usage of the poectl application is done by running the following command:

```
:~$ poectl [OPTIONS] PORT | all
```

To enable PoE on a port follow the following command:

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
