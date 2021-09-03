---
title: debugging
parent: Tools
---

# Debugging

For debug purposes, refer to this page for instructions in enabling the debug options in BISDN Linux.

## Debug instructions

First check that all necessary services are up and running with the following command. To ensure proper operation of BISDN Linux, ``baseboxd``, ``ofdpa``, ``ofdpa-grpc`` and ``ofagent`` must be running.

```
systemctl status <service>
```

To follow the logs from the service, use the following command. Check `man journalctl` for more information on the arguments.

```
journalctl -u <service>
```

To debug the status on the ports, check `onlpdump -S` to get the state on the port. Similar output can be seen below. If the port information does not correspond to the physical connections, debug the physical connection by adding another cable or try another module, if available.

```
Port  Type            Media   Status  Len    Vendor            Model             S/N
----  --------------  ------  ------  -----  ----------------  ----------------  ----------------
48  NONE
...
51  1GBASE-CX       Copper          1m            SFP-10G-DAC     
```

When trying to configure a feature, please remember to verify if the version you are checking does support the feature. Additionally, is a list of feature limitations [here](https://docs.bisdn.de/limitations.html).

## Debug files

### baseboxd debug files

baseboxd is packaged with the following configuration file `/etc/default/baseboxd`, visible below.

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

The relevant options for enabling debug logs in baseboxd is the `GLOG_v=0` value. By increasing the value in this configuration option, more detailed debug information will be outputted.

When passing the baseboxd module names to `GLOG_vmodule`, which correspond to the class names, specific logging for that component will be activated with the specified logging level. The following command exemplifies how to configure this value.

```
GLOG_vmodule=<module name>=<log level>
For example, setting logging to the main loop, the layer 3 and the controller classes,
GLOG_vmodule=cnetlink=1,nl_l3=3,controller=2 
```

### ofdpa debug files 

ofdpa is packaged with the configuration file `/etc/default/ofdpa`, visible below.

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

To activate the logging components inside ofdpa pass the `-c <component>` flag with the component, and to set the level for all components `-d <level>`.

### ofagent debug files

ofagent is packaged with the configuration file `/etc/default/ofagent`, visible below.

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

Logging in ofagent can be controlled with the `-a <log level>` flag.

### FRR debug instructions

Refer to the official FRR documentation for the instructions in activating the debug components [FRR documentation](http://docs.frrouting.org/en/latest/).

