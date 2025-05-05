---
title: Configure Baseboxd
parent: Getting Started
nav_order: 4
---

# First steps with BISDN Linux

## Logging into the Switch

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
