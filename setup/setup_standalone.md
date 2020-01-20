---
date: '2020-01-07T16:07:30.187Z'
docname: setup/setup_standalone
images: {}
path: /setup-setup-standalone
title: System Configuration
nav_order: 5
---

# System Configuration

## Setup a single Basebox switch or router

We assume the ONIE installation of BISDN Linux was successful. For more information on ONIE installation please refer to the section [Install BISDN Linux](install_switch_image.html).

### Getting started

Log into the switch with the following credentials:

```
USER = "basebox"
PASSWORD = "b-isdn"
```

BISDN Linux, as most other Linux systems, requires superuser privileges to run commands that change system settings. The examples below must then be run via sudo to succeed.
BISDN Linux makes use of [systemd](https://github.com/systemd/systemd). There are several systemd-enabled services required that turn a whitebox switch into a router:

* ofdpa
* ofdpa-grpc
* ofagent
* baseboxd
* frr

You may start/stop/query a service like this:

```
systemctl start | stop | restart | enable | disable | status SERVICE.service
```

where for example the command to show information about baseboxd would be `systemctl status baseboxd.service`.

### Configure a local or remote controller

BISDN Linux contains the prerequisites to control the switch by either local or remote OpenFlow controllers. The default configuration is a local controller.
Run the following scripts in the BISDN Linux shell to configure the local or remote usage.

To configure a local baseboxd controller, where the default OpenFlow port 6653 is used:

```
basebox-change-config -l baseboxd
```

To configure a local Ryu controller:

```
basebox-change-config -l ryu-manager ryu.app.ofctl_rest
```
BISDN Linux supports to use [Ryu](https://osrg.github.io/ryu/) as the controller, where the last argument is the Ryu application. If you have a file for a custom application, please use the absolute path to the application file.

To configure a remote OpenFlow controller with <IP-address> and <OpenFlow-port>:

```
basebox-change-config -r <IP-address> <OpenFlow-port>
```

### Verify your configuration

You can check the results of your configuration in the following file: /etc/default/ofagent

The section “OPTION=” should point to localhost (local controller) or to the remote controller and respective port that you have configured.

### See the installed software components

Check if the required software components are installed.

#### Local controller (BISDN Linux)

To check whether the proper packages are installed on BISDN Linux run

```
opkg info service-name
```

The following components should be installed on the whitebox switch by default: baseboxd, ofagent, ofdpa, ofdpa-grpc, frr.

```
opkg info baseboxd; \
opkg info ofagent; \
opkg info ofdpa; \
opkg info ofdpa-grpc; \
opkg info frr
```

#### Remote controller

The following components should be installed and running on the remote controller: baseboxd, frr, ryu-manager (optional):

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
systemctl restart baseboxd
```

## Configure advanced features

### Configure source-MAC learning

Source-MAC learning is enabled by default. It is a feature of L2 bridging. For more information on how a typical switch learns MAC adresses, please refer to this article: [transparent bridging](https://en.wikipedia.org/wiki/Bridging_(networking)). 

In case you do not want the switch to learn MAC adresses automatically, e.g. when you want to learn them via a specific controller logic, you may disable this feature.

**Note**: Packets are generally flooded if no learning mechanism is enabled.
{: .label .label-yellow }

To permanently disable source-MAC learning, edit the file /etc/ofdpa-grpc.conf and add the flag --disable_srcmac_learning to the `OPTIONS=` line, e.g.
```
OPTIONS="--disable_srcmac_learning"
```
Restart ofdpa-grpc to apply changes.

You can als run the following grpc calls to enable/disable source-MAC learning:

```
grpc_cli call <IP>:50051 ofdpaSourceMacLearningSet "enable: true"
```

Read the current state:

```
grpc_cli call <IP>:50051 ofdpaSourceMacLearningGet ""
```

**WARNING**: The switch platforms do not yet include or support running the grpc_cli tool. This command can only be executed from an external server with grpc_cli installed.
{: .label .label-red }

### Port mirroring

BISDN Linux supports the configuration of mirror ports. Add mirror ports like that (replace <IP> with the IP of the whitebox switch):

```
grpc_cli call <IP>:50051 ofdpaMirrorPortCreate "port_num: 1"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS}"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS_EGRESS}"
```

See mirror port configuration by running the following command on the whitebox switch:

```
client_mirror_port_dump
```

Mirror ports can be deleted according to the following commands:

```
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }"
grpc_cli call <IP>:50051 ofdpaMirrorPortDelete "port_num: 1"
```

**WARNING**: The switch platforms do not yet include or support running the grpc_cli tool. This command can only be executed from an external server with grpc_cli installed.
{: .label .label-red }

### Enabling auto-negotiation

To enable auto-negotiation on ports use the client_drivshell tool. To enable it on e.g. the first switch port simply run:

```
client_drivshell port xe0 AN=on
```

Use the following command to print the current port configuration:

```
client_drivshell ports
```

The port xe0 (port 1) should now have auto-negotiation enabled (YES) and since AN=off is the default, all other ports should have set it to NO. In the example below, a 1G active copper SFP is attached to port 1 and the speed has been set accordingly. All other ports have set the speed to 10G by default.

```
$ client_drivshell ports
          ena/    speed/ link auto    STP                  lrn  inter   max  loop
    port  link    duplex scan neg?   state   pause  discrd ops   face frame  back
 xe0(  1)  up      1G  FD   SW  Yes  Forward          None    F   GMII  9412
 xe1(  2)  up     10G  FD   SW  No   Forward          None    F    SFI  9412
```

### Disable auto-negotiation

To disable auto-negotiation run the following command:

```
client_drivshell port xe0 AN=off SP=10000
```

The parameter SP takes the speed you want to configure, in the example above it is 10G. For information how to verify your configuration, please see the section above.

### Persistent port configuration

Switch port configuration can be persisted across restarts. In order to turn off auto-negotiation for the ports xe0 and xe1 one would run

```
client_drivshell port xe0 AN=off SP=10000
client_drivshell port xe1 AN=off SP=10000
```

To make the commands persist one would add the following lines to the file /etc/ofdpa/rc.soc

```
port xe0 AN=off SP=10000
port xe1 AN=off SP=10000
exit
```

Note the absence of client_drivshell and the single exit statement at the end.

## Bundled software with BISDN Linux

### basebox-support

The basebox-support script enables customers to create a tar file with the current switch state. It gathers information like port status, system logs and configuration, to ease debugging and reporting errors on the switch platform. To execute properly, please run basebox-support on the switch with root privileges.

### bisdn-change-config

A bash script for setting up the OpenFlow endpoint for the baseboxd/ryu controllers, by configuring the ofagent and baseboxd/Ryu (only in case of local controller) configuration files.

```
Execution:
  -r, --remote : $0 -r <remote controller IP address> <remote controller port>
  -l, --local : $0 -l { baseboxd | ryu-manager APPLICATION-FILE }
  -v, --view : view the ofagent config
  -h, --help : print this message
```

### OF-DPA Client tools

These tools enable you to interact with the OF-DPA layer and can be used to cross-check controller behavior and configuration. The following commands can be used to show the flow, group tables and ports, respectively:

```
client_flowtable_dump
client_grouptable_dump
client_port_table_dump
```

### onlpdump

This tool can be used to show detailed information about the system/platform, the fan-control, the LEDs and the attached modules:

```
Usage: onlpdump [OPTIONS]
  -d   Use dump(). This is the default.
  -s   Use show() instead of dump().
  -r   Recursive show(). Implies -s
  -e   Extended show(). Implies -s
  -y   Yaml show(). Implies -s
  -o   Dump ONIE data only.
  -x   Dump Platform Info only.
  -j   Dump ONIE data in JSON format.
  -m   Run platform manager.
  -M   Run as platform manager daemon.
  -i   Iterate OIDs.
  -p   Show SFP presence.
  -t   <file>  Decode TlvInfo data.
  -O   <oid> Dump OID.
  -S   Decode SFP Inventory
  -b   Decode SFP Inventory into SFF database entries.
  -l   API Lock test.
  -J   Decode ONIE JSON data.
```

### FRRouting

BISDN Linux comes with FRR pre-installed. Please follow the [FRR User Guide](http://docs.frrouting.org/en/latest/) for further information.

#### Using FRR and ZEBRA

When using FRR you can also store network configuration via ZEBRA in /etc/frr/zebra.conf. For details please see the [Zebra manual](http://docs.frrouting.org/en/latest/zebra.html).
The example below shows how to configure an IPv6 address on a port.

```
hostname basebox
log file zebra.log

interface port40
  no shutdown
  ipv6 address 2003:db01:0:21::1/64
  no ipv6 nd suppress-ra
  ipv6 nd prefix 2003:db01:0:21::/64
```

## Persisting network configuration

Multiple ways of storing network configuration exist on Linux systems. BISDN Linux supports :ref:”systemd-networkd” , [FRR User Guide](http://docs.frrouting.org/en/latest/) for single Basebox setups.

systemd-networkd uses .network files to store network configuration. For details please see the [systemd-networkd manual](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
The .network files (in directory /etc/systemd/network/) are processed in lexical order and only the first file that matches is applied.

In the example below, the file 20-port50.network is processed first, meaning that port50 will get a dedicated configuration while all other ports get the generic one.
That also means port50 is not getting the configuration for LLDP, but all other ports do (as these are configured using file 30-port.network)

```
root@agema-ag7648:/etc/systemd/network# cat 20-port50.network
[Match]
Name=port50

[Network]
Address=10.20.30.20/24

root@agema-ag7648:/etc/systemd/network# cat 30-port.network
[Match]
Name=port*

[Network]
LLDP=yes
EmitLLDP=yes
LLMNR=no
```
