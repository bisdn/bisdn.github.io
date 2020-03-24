---
title: Connecting To The Switch
parent: Getting Started
nav_order: 1
---

## Connect to the switch console

Connect the CONSOLE port of the switch to a computer of your choice. We
recommend using the tool kermit to connect to the switch console. If a Linux
machine is used, install ckermit, edit a file named .kermrc and put in your
configuration with the used line port.

Example of .kermrc:

```
set line /dev/ttyUSB0
set speed 115200
set carrier-watch off
set flow-control xon/xoff
connect
```
