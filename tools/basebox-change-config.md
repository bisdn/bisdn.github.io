---
title: basebox-change-config
parent: Tools
---

# basebox-change-config

A bash script for setting up the OpenFlow endpoint for the baseboxd/ryu
controllers, by configuring the ofagent and baseboxd/Ryu (only in case of local
controller) configuration files.

```
Execution:
  -r, --remote : $0 -r <remote controller IP address> <remote controller port>
  -l, --local : $0 -l { baseboxd | ryu-manager APPLICATION-FILE }
  -v, --view : view the ofagent config
  -h, --help : print this message
```
