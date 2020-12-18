---
title: Auto Negotiation
parent: Platform Configuration
nav_order: 3
---

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

### Auto-negotiation and bonded interfaces

Auto-negotiation is a property of physical ports, while bond interfaces are logical ports. So any auto-negotiation configuration needs to be set for the individual bond members.
