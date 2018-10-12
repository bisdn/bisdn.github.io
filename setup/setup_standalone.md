# Setup a standalone Basebox router

We assume that the ONIE installation of the switch image was successful. For more information on ONIE installation please refer to the [previous section](install_switch_image). 

## Getting started 

Log into the switch (username: root), enable ip_routing and the switch will become a router:

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

BISDN Linux makes use of [systemd][systemd], so there are a handful of services that get the networking running:
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

BISDN Linux contains the prerequisites to control the switch by either local or remote OpenFlow controllers.
The local OpenFlow Agent can connect to a controller endpoint specified in the file

```
/usr/default/ofagent 
```

The line `OPTIONS="-t 127.0.0.1:6653 -m"` should be changed to point to any remote controller address and TCP port number.

After you have modified the file, make sure to restart the ofagent service. 

```
systemctl restart ofagent
```

## Using baseboxd

Following this, start the baseboxd controller (or make sure it is running locally).

```
systemctl restart baseboxd
```

After a short while (1 to 2 seconds) you should see the list of switch ports being exposed to the local host.

```
ip link show
```

Note that the ports that you see (port1, port2, ... port54) are numbered as on the switch. The ports are Linux tap devices by nature, and are not the real physical ports (remember, there is a separation of control and data in SDN, the tap interfaces are merely handles for the "real" physical ports on the switch. Therefore, dumping all traffic coming in to a specific port via, e.g., tcpdump, will not give the desired effect unless you have created an OpenFlow rule to literally send all traffic coming in to a certain port up to the controller. For most switches, the data rate even of a 10G port would be too high to pipe all traffic through the OpenFlow channel)

You can see the output log of baseboxd by means of 

```
journalctl -u baseboxd -f
```

Note that this works for all other services, too. Sometimes it is particularly helpful to look at the output of the ofdpa service, as this contains some useful output from the client_drivshell command line interface.

## Client tools
Client tools enable you to interact with the OF-DPA layer. The following commands can be used to show the flow and grouptables, respectively:

```
client_flowtable_dump
client_grouptable_dump
```



## onlpdump

This tool  can be used to show information about the attached modules. Use

```
onlpdump
```

to see details:


```
  41  NONE
  42  NONE
  43  10GBASE-CR      Copper          2m     Amphenol          610530004         APF15510044P20  
  44  NONE
  45  10GBASE-SR      Fiber                  x-ion             SFP-10GSR-85      E0707240349     
  46  NONE
  47  10GBASE-SR      Fiber                  x-ion             SFP-10GSR-85      E0707240348     
  48  NONE
  49  NONE
  50  NONE
```

## Additional resources
* [systemd GitHub Repository][systemd]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[systemd]: https://github.com/systemd/systemd (systemd on github)


