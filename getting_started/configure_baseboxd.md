---
title: Configure Baseboxd
parent: Getting Started
nav_order: 4
---

# Configure Baseboxd as SDN Controller

## Getting started

Log into the switch with the following credentials:

```
USER = "basebox"
PASSWORD = "b-isdn"
```

You should then see the console of BISDN Linux. You can also display the OS
information by running `cat /etc/os-release`.

BISDN Linux, as most other Linux systems, requires superuser privileges to run
commands that change system settings. The examples below must then be run via
sudo to succeed.

BISDN Linux makes use of [systemd](https://github.com/systemd/systemd). There
are several systemd-enabled services required that turn a whitebox switch into
a router:

* ofdpa
* ofdpa-grpc
* ofagent
* baseboxd
* frr

You may start/stop/query a service like this:

```
systemctl start | stop | restart | enable | disable | status SERVICE.service
```

where for example the command to show information about baseboxd would be
`systemctl status baseboxd.service`.

### System and component versions

Checking the versions of packages, like the ones listed above, can be done
using

```
sudo opkg info <package name>
```

You can also print all installed packages with their associated versions with

```
sudo opkg list_installed
```

For the current version of baseboxd, simply run

```
baseboxd --version
```

List information about the BISDN Linux release with

```
cat /etc/os-release
```

And information about the build date and linux kernel can be found via

```
uname -a
```

### Configure a local or remote controller

BISDN Linux contains the prerequisites to control the switch by either local or
remote OpenFlow controllers. The default configuration is a local controller,
with BISDN Linux currently supporting
[baseboxd](https://github.com/bisdn/basebox) and
[Ryu](https://osrg.github.io/ryu-book/en/html/index.html).

Run the following scripts in the BISDN Linux shell to configure the local or
remote controller.

#### Local controller

To configure a local baseboxd controller using the default OpenFlow port 6653:

```
sudo basebox-change-config -l baseboxd
```

To configure a local Ryu controller:

```
sudo basebox-change-config -l ryu-manager ryu.app.ofctl_rest
```

where `ryu.app.ofctl_rest` is the Ryu application. If you have a file for a
custom application, please use the absolute path to the application file.

Please note that with Ryu the integration of Linux networking (netlink) events
is not supported, as that is a feature from baseboxd.
{: .label .label-yellow }

#### Remote controller

To configure a remote OpenFlow controller with \<IP-address\> and
\<OpenFlow-port\>:

```
sudo basebox-change-config -r <IP-address> <OpenFlow-port>
```

### Verify your ofagent configuration

You can check the results of your configuration in the following file:
/etc/default/ofagent

The section “OPTION=” should point to localhost (local controller) or to the
remote controller and respective port that you have configured.

### Setup baseboxd

The baseboxd configuration file located in '/etc/default/baseboxd' allows you
to set flags for which ports to listen on and for enabling/disabling multicast
and KNET interfaces. The default configuration file shows the basic structure:

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
#
# Use KNET interfaces:
# FLAGS_use_knet=true
#
# Mark switched packets as offloaded:
# FLAGS_mark_fwd_offload=true
#
# Vlan ID used for untagged traffic on unbridged ports (1-4095):
# FLAGS_port_untagged_vid=1

### glog
#
# log to stderr by default:
GLOG_logtostderr=1

# verbose log level:
# GLOG_v=0

# verbose per-module log level:
# GLOG_vmodule=
```

#### Logging options

We use the [Google Logging Library](https://hpc.nih.gov/development/glog.html)
for logging. This includes the
[GLOG_vmodule](https://hpc.nih.gov/development/glog.html#verbose) that allows
you to set the log level for specific sub-modules.

The numbers of severity levels `INFO`, `WARNING`, `ERROR`, and `FATAL`
are `0`, `1`, `2` and `3`, respectively.

The default configuration, as shown in the above section, logs all messages at
level `INFO` and above to stderr.

You can reduce log verbosity by setting `minloglevel`.

```
# log to stderr by default:
GLOG_logtostderr=1

# Only show WARNING ERROR and FATAL level messages
GLOG_minloglevel=1 
```

##### Verbose logging

glog also supports verbose logging levels, asecending from 0.

These are defined separately as `GLOG_v*` options. This can be enabled globally
in the baseboxd configuration file using the following syntax.

**Note:** Verbose logging requires the INFO level to be enabled.

```
GLOG_v=2
```

You can also set verbose logging levels on a per-module basis:

For example, if you want to set the log levels for the
[cnetlink](https://github.com/bisdn/basebox/blob/master/src/netlink/cnetlink.h)
and
[nl_bridge](https://github.com/bisdn/basebox/blob/master/src/netlink/nl_bridge.h)
sub-modules to 3 and 2, respectively, simply add the following line to the
configuration file:

```
GLOG_vmodule=cnetlink=3,nl_bridge=2
```

##### File-based logging

glog can also be configured to log to files.
The default level is `INFO`. You can use the `stderrthreshold` to send the most
important messages to stderr, whilst writing everything including
`INFO` level and verbose logs to a file.

Files are written to the log directory, with INFO, ERROR etc. files.
Each file contains any log messages ar the named level or greater.

A symlink is created for the latest file for each level e.g `basebox.INFO`.

```
# Enable logging to stderr and to a file
# Note, default of GLOG_logtostderr=1 must be commented out
# GLOG_logtostderr=1
# Log anything WARN and above to standard error
GLOG_stderrthreshold=2
# Defaults to /tmp. Note: not created automatically
GLOG_log_dir=/var/log/baseboxd
```

###### Creating log directory automatically

You can configure systemd to create the directory automatically by running
`sudo systemctl edit baseboxd` and adding the below lines to the file.

Note, the path must be relative to `/var/log` to use this mechanism.
e.g `/var/log/baseboxd`, as shown above, becomes `baseboxd`.

```
[Service]
LogsDirectory=baseboxd
```

You can then apply the changes by running `sudo systemctl daemon-reload` and
following the steps in the next section.

## Applying configuration changes

In order to apply changes in the baseboxd configuration you can either reboot
the switch:

```
reboot
```

or restart the baseboxd service:

```
sudo systemctl restart baseboxd
```
