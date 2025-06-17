---
title: Connecting To The Switch
parent: Getting Started
nav_order: 1
---

## Connect to the switch console

Connect the CONSOLE port of the switch to a computer of your choice. If a Linux machine is used, multiple client applications are available to connect to the switch console.

Here, we provide instructions for [minicom](https://linux.die.net/man/1/minicom) and [ckermit](http://www.columbia.edu/kermit/ckututor.html), assuming the switch is connected in port `/dev/ttyUSB0`.

### minicom

The default configurations of minicom can be used to connect to the switch, with exception of the console port and hardware flow control. Running minicom in a command line with the following command will start it in setup mode (omit the `-s` for skip setup):

```
sudo minicom -s -D /dev/ttyUSB0
```

In `Serial port setup`, set hardware flow control to `No` by pressing `F`. Exit setup by pressing `esc` and minicom will then connect to the switch.

### ckermit

After installing ckermit, edit a file named .kermrc in your home folder with configurations as follows:

```
set line /dev/ttyUSB0
set speed 115200
set carrier-watch off
set flow-control xon/xoff
connect
```

Run kermit with the following command:

```
kermit .kermrc
```

After following this page, you can continue to the [ONIE installation](install_onie.md), or if your switch already has ONIE installed then [Install BISDN Linux](install_bisdn_linux.md).
