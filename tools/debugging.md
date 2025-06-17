---
title: debugging
parent: Tools
---

# Debugging

For debug purposes, refer to this page for instructions on enabling the debug
options in BISDN Linux.

## Debug instructions

To ensure proper operation of BISDN Linux, the services ``baseboxd``,
``ofdpa``, ``ofdpa-grpc`` and ``ofagent`` must be running.
First check that these necessary services are up and running with the following
command.

```
systemctl status <service>
```

Before diving deeper into the debugging process, you should verify your network
configuration. Make sure that the network configuration files are read and
applied correctly, by checking the status and logs of services that you are
using to apply network configuration. In most cases this will be
``systemd-networkd``, and maybe ``frr``.

To follow the logs from the service, use the following command.

```
journalctl -u <service>
```

Check `man journalctl` for more information on the arguments.

When trying to configure a feature, please remember to verify if the version
and plaform being tested does support the feature. Make sure to check the list
of known [limitations](https://docs.bisdn.de/limitations.html).

To ensure that the link state itself is as expected, use `onlpdump -S` to get
the state of all ports (sample output below). If the port state and SFP
information (not applicable to patch cables) does not correspond to the
physical connections, debug the physical connection by adding another cable or
try another module, if available.

```
Port  Type            Media   Status  Len    Vendor            Model             S/N
----  --------------  ------  ------  -----  ----------------  ----------------  ----------------
48  NONE
...
51  1GBASE-CX       Copper          1m            SFP-10G-DAC
```

## Debug files

### baseboxd debug files

baseboxd ships with the default configuration file `/etc/default/baseboxd`
shown below.

```
### Configuration options for baseboxd
#
# Enable multicast support:
# FLAGS_multicast=true
#
# Listening port:
# FLAGS_port=6653
#
# gRPC listening port:
# FLAGS_ofdpa_grpc_port=50051

### glog
#
# log to stderr by default:
GLOG_logtostderr=1

# verbose log level:
# GLOG_v=0
```

The relevant option for enabling debug logs in baseboxd is the `GLOG_v` key. By
increasing the value in this configuration option (default is 0 for disabled),
more detailed debug information will be printed. The accepted values are
`GLOG_v=[1..5]`.

When passing the baseboxd module names to `GLOG_vmodule`, which correspond to
the class names, specific logging for that component will be activated with the
specified logging level. The following command exemplifies how to configure
this value.

```
GLOG_vmodule=<module name>=<log level>
set log levels of the cnetlink, nl_l3 and controller modules to 1, 3 and 2 respectively.
GLOG_vmodule=cnetlink=1,nl_l3=3,controller=2
```

### ofdpa debug files

ofdpa ships with the default configuration file `/etc/default/ofdpa` shown below.

```
### Configuration options for ofdpa
#
# Set the component for debugging (can be added multiple times),
# valid components are:
#        1 = API
#        2 = Mapping
#        3 = RPC
#        4 = OFDB
#        5 = Datapath
#        6 = G8131
#        7 = Y1731
# e.g. (API and Mapping):
# -c 1 -c 2
#
# debug level 0..4 (all components)
# -d 2
#
# example:
# OPTIONS="-c 1 -c 2 -d 2"
OPTIONS=""
```

To activate the logging for ofdpa, pass the component identifier (the numbers
show in the default configuration file), together with the debug level you need
to the `OPTIONS` key (e.g. `OPTIONS="-c 1 -c 5 -d 4"` to enable the maximum
verbosity for the "API" and "DATAPATH" components).

### ofagent debug files

ofagent ships with the default configuration file `/etc/default/ofagent` shown
below.

```
### Configuration options for ofagent
#
# set the dpid
# -i 1
#
# connect to IP:PORT
# -t 10.10.10.10:6653
#
# agent level debugging 0..2
# -a 2
#
# insert all options here:
OPTIONS="-t 127.0.0.1:6653 -m"
```

Logging in ofagent can be enabled by amending the `OPTIONS` key (please do not
overwrite the default settings) with the `-a <log level>` flag (e.g.
`OPTIONS="-t 127.0.0.1:6653 -m -a 2"` for maximum verbosity).

### FRR debug instructions

You can check the service status and logs of FRR like we do for all other
services above.
For more information we refer to the official FRR documentation for the
instructions in activating the debug components [FRR documentation](http://docs.frrouting.org/en/latest/).
