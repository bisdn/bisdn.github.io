# Setup a single Basebox switch or router

We assume that the ONIE installation of BISDN Linux was ssuccessful. For more information on ONIE installation please refer to the [previous section](install_switch_image.html).

## Getting started

Log into the switch with the following credentials:

```
USER = "basebox"

PASSWORD = "b-isdn"
```

BISDN Linux, as most other Linux systems, requires to run commands that change system settings with superuser privileges. The examples below must then be run via `sudo` to succeed.

BISDN Linux makes use of [systemd][systemd]. There are several services required that turn a whitebox switch into a router:
* ofdpa
* ofdpa-grpc
* ofagent
* baseboxd
* frr

You may start/stop/query a service like for example:

```
systemctl start ofdpa
systemctl stop ofdpa
systemctl status ofdpa
```
## Configure a local or remote controller

BISDN Linux contains the prerequisites to control the switch by either local or remote OpenFlow controllers. The default configuration is a local controller.
Run the following scripts on the whitebox switch to configure the local or remote usage:

### Local baseboxd controller
`basebox-change-config -l baseboxd` where the default OpenFlow port `6653` is used.

### Local Ryu controller
BISDN Linux supports to use [Ryu][Ryu] as the controller:

`basebox-change-config -l ryu-manager ryu.app.ofctl_rest`

where the last argument is the Ryu application. If you have a file for a custom application, please use the absolute path to the application file.

### Remote controller
`basebox-change-config -r 172.16.10.10 6653` where the IP-address and port must point to the remote controller

## Verify your configuration

You can check the results of your configuration in the following file: `/etc/default/ofagent`

The section "OPTION=" should point to localhost (local controller) or to the remote controller and respective port that you have configured.

## See the installed software components

Check if the required software components are installed.

### Local controller (BISDN Linux)

To check whether the proper packages are installed on BISDN Linux run

`opkg info service-name`

The following components should be installed on the whitebox switch by default:
`baseboxd`, `ofagent`, `ofdpa`, `ofdpa-grpc`, `grpc_cli`, `ffr`

e.g.:
```
opkg info baseboxd; \
opkg info ofagent; \
opkg info ofdpa; \
opkg info ofdpa-grpc; \
opkg info frr
```

### Remote controller

The following components should be installed on the remote controller:
`baseboxd`, `ffr`, `ryu-manager` (optional)

## Verify the running services

You can check if the respective services are running.

### Local controller (BISDN Linux)

The following services should be active (running) and enabled on the whitebox switch by default:
`baseboxd`, `ofagent`, `ofdpa`, `ofdpa-grpc`

### Remote controller

The following components should be active (running) and enabled on the whitebox switch:
`ofagent`, `ofdpa`, `ofdpa-grpc`

The following components should be inactive and disabled on the whitebox switch:
`baseboxd`, `ryu-manager`

The following components should be active (running) and enabled on the remote controller:
`baseboxd`, `frr`, `ryu-manager` (optional)

Example for systemd commands:
```
systemctl status baseboxd; \
systemctl status ofagent; \
systemctl status ofdpa; \
systemctl status ofdpa-grpc; \
systemctl status ryu-manager
```

## Using baseboxd

baseboxd uses a config file to set e.g. [GLOG loglevels][GLOG] and OpenFlow ports. On BISDN Linux this configuration data is stored in `/etc/default/baseboxd` and on Fedora systems in `/etc/sysconfig/baseboxd`. The example below shows the basic structure:

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

After having made changes to this file, restart baseboxd:

```
systemctl restart baseboxd
```

After a short while (2 seconds) you should see the list of switch ports being exposed to the local host via:

```
ip link show
```

Note that the ports that you see (port1, port2, ... port54) are numbered as on the switch. The ports are Linux tap devices by nature, and are not the real physical ports (remember, there is a separation of control and data in SDN, the tap interfaces are merely handles for the "real" physical ports on the switch. Therefore, dumping all traffic coming in to a specific port via, e.g., tcpdump, will not give the desired effect unless you have created an OpenFlow rule to literally send all traffic coming in to a certain port up to the controller. For most switches, the data rate even of a 10G port would be too high to pipe all traffic through the OpenFlow channel)

You can see the output log of baseboxd by means of

```
journalctl -u baseboxd -f
```

Note that this works for all other services, too. Sometimes it is particularly helpful to look at the output of the OF-DPA service, as this contains some useful output from the client_drivshell command line interface.

## Read the switch information via client tools
Client tools enable you to interact with the OF-DPA layer and can be used to cross-check controller behavior and configuration. The following commands can be used to show the flow, grouptables and ports, respectively:

```
client_flowtable_dump
client_grouptable_dump
client_port_table_dump
```
## onlpdump

This tool can be used to show detailed information about the system/platform, the fan-control, the LEDs and the attached modules:

```
onlpdump
```
## FRRouting

BISDN Linux comes with [FRRouting][frr] pre-installed. Please follow the [FRRouting User Guide][FRRouting User Guide].

## Persisting storage of network configuration

Multiple ways of storing network configuration exist in Linux. We support [systemd-networkd][systemd-networkd-mp], [FRRouting][FRRouting User Guide] for single Basebox setups. 
For [Basebox Fabric][fabric] we also integrated a distributed [etcd-cluster][api_definition] database.

### Using systemd-networkd

systemd-networkd uses `.network` files to store network configuration. For details please see the [systemd-networkd man page][systemd-networkd-mp]. 
The `.network` files (in directory `/etc/systemd/network/`) are processed in lexical order. In the example below, the file `20-port50.network` is processed first, 
meaning that port50 will get a dedicated configuration while all other ports get the basic one. Since only the first file that matches a port is processed, 
that also means port50 is __not__ getting the configuration for LLDP, but all other ports do (as these are configured using file `30-port.network`)

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

### Using FRR and ZEBRA

When using FRR you can also store network configuration via ZEBRA in `/etc/frr/zebra.conf`. For details please see the [ZEBRA manual][zebra_manual]. 
The example below shows how to configure an IPv6 adress on a port.

```
hostname basebox
log file zebra.log

interface port40
  no shutdown
  ipv6 address 2003:db01:0:21::1/64
  no ipv6 nd suppress-ra
  ipv6 nd prefix 2003:db01:0:21::/64
```

## Additional resources
* [systemd GitHub Repository][systemd]
* [systemd-networkd man page][systemd-networkd-mp]
* [FRRouting github page][frr]
* [FRRouting User Guide][FRRouting User Guide]
* [Ryu SDN framework][Ryu]
* [GLOG How To][GLOG]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[systemd]: https://github.com/systemd/systemd (systemd on github)
[systemd-networkd-mp]: https://www.freedesktop.org/software/systemd/man/systemd.network.html (systemd-networkd man page)
[frr]: https://github.com/FRRouting/frr (FRRouting on github)
[FRRouting User Guide]: http://docs.frrouting.org/en/latest/ (FRRouting User Guide)
[Ryu]: https://osrg.github.io/ryu/ (Ryu SDN framework)
[GLOG]: http://rpg.ifi.uzh.ch/docs/glog.html (How To Use Google Logging Library)
[fabric]: ../introduction/introduction_overall_system_architecture.html
[api_definition]: ../api/api_definition.html
[zebra_manual]: http://docs.frrouting.org/en/latest/zebra.html (zebra manual)
