---
title: onlpdump
parent: Tools
---

# onlpdump

This tool can be used to show detailed information about the system/platform,
the fan-control, the LEDs and the attached modules:

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
