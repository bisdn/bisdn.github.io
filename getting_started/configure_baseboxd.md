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
You should then see the console of BISDN Linux. You can also display the OS information by running `cat /etc/os-release `.

BISDN Linux, as most other Linux systems, requires superuser privileges to run commands that change system settings. The examples below must then be run via sudo to succeed.
BISDN Linux makes use of [systemd](https://github.com/systemd/systemd). There are several systemd-enabled services required that turn a whitebox switch into a router:

* ofdpa
* ofdpa-grpc
* ofagent
* baseboxd
* frr

You may start/stop/query a service like this:

```
sudo systemctl start | stop | restart | enable | disable | status SERVICE.service
```

where for example the command to show information about baseboxd would be `systemctl status baseboxd.service`.

### Verify the running software components

#### Local controller (BISDN Linux)

The following services should be active (running) and enabled on the whitebox switch by default:

* baseboxd
* ofagent
* ofdpa
* ofdpa-grpc

#### Remote controller

The following components should be active (running) and enabled on the whitebox switch:

* ofagent
* ofdpa
* ofdpa-grpc

The following components should be inactive and disabled on the whitebox switch:

* baseboxd
* ryu-manager

The following components should be active (running) and enabled on the remote controller:

* baseboxd
* frr
* ryu-manager

### System and installed software component versions

Checking the versions of packages, like the ones listed above, can be done using

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

BISDN Linux contains the prerequisites to control the switch by either local or remote OpenFlow controllers. The default configuration is a local controller.
Run the following scripts in the BISDN Linux shell to configure the local or remote usage.

To configure a local baseboxd controller, where the default OpenFlow port 6653 is used:

```
sudo basebox-change-config -l baseboxd
```

To configure a local Ryu controller:

```
sudo basebox-change-config -l ryu-manager ryu.app.ofctl_rest
```
BISDN Linux supports to use [Ryu](https://osrg.github.io/ryu/) as the controller, where the last argument is the Ryu application. If you have a file for a custom application, please use the absolute path to the application file.

To configure a remote OpenFlow controller with <IP-address> and <OpenFlow-port>:

```
sudo basebox-change-config -r <IP-address> <OpenFlow-port>
```

### Verify your configuration

You can check the results of your configuration in the following file: /etc/default/ofagent

The section “OPTION=” should point to localhost (local controller) or to the remote controller and respective port that you have configured.

### Setup baseboxd

baseboxd uses a file to store configuration data like log level and OpenFlow ports. On BISDN Linux this file is located in /etc/default/baseboxd and on Fedora systems in /etc/sysconfig/baseboxd. The example below shows the basic structure:

```
### Configuration options for baseboxd
#
# Listening port:
# FLAGS_port=6653

### glog
#
# log to stderr by default:
GLOG_logtostderr=1

# verbose log level:
# GLOG_v=0
```

After having made the necessary changes to this file, restart baseboxd to apply the changes:

```
sudo systemctl restart baseboxd
```
