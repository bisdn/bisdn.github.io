# Advanced setup

## SFP modules

BISDN Linux supports SFP modules (otical or active copper) as well as direct attached cables (DAC). By default, BISDN Linux has disabled auto-negotiation on all ports (AN=off). On platforms like the AG7648 by default 10G is configured on all ports.

### Enabling auto-negotiation

To enable auto-nagotiation on ports use the `client_drivshell` tool. To enable it on port 1 run:

```
client_drivshell port xe0 AN=on
```

Use the following command to print the current port configuration to the journal:

```
client_drivshell ports
```

See the journal logs:

```
journalctl -u ofdpa -e
```

Port 1 should have auto neg enabled (YES) while port 2 (and all other ports) should have set it to NO. In the example, a 1G active copper SFP is attached to port 1 and the speed has been set accordingly. All other ports have set the speed to 10G by default.

```
Nov 29 09:00:17 agema-ag7648 ofdpa[7389]:                  ena/    speed/ link auto    STP                  lrn  inter   max  loop
Nov 29 09:00:17 agema-ag7648 ofdpa[7389]:            port  link    duplex scan neg?   state   pause  discrd ops   face frame  back
Nov 29 09:00:17 agema-ag7648 ofdpa[7389]:        xe0(  1)  up      1G  FD   SW  Yes  Forward          None    F   GMII  9412
Nov 29 09:00:17 agema-ag7648 ofdpa[7389]:        xe1(  2)  up     10G  FD   SW  No   Forward          None    F    SFI  9412
```

### Disable auto-negotiation

To disable auto-negotiation run the following command:

```
client_drivshell port xe0 AN=off SP=10000
```

The parameter SP takes the speed you want to configure, in the example it is 10G. For information how to check your config, please see the section above.

## Additional resources
* [OF-DPA GitGub Repository][ofdpa]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[ofdpa]: https://github.com/Broadcom-Switch/of-dpa (OF-DPA GitHub repository)

