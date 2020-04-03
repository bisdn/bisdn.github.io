---
title: ONIE Tools
parent: Tools
---

# ONIE Tools

All BISDN Linux images contain some scripts that allow a more convenient handling of common ONIE tasks. These tools and their handling are described below.

## onie-bisdn-uninstall

The script `onie-bisdn-uninstall` enables you to uninstall a running BISDN Linux. The corresponding man pages and usage help can be displayed like this:

```
man onie-bisdn-uninstall
onie-bisdn-uninstall -h
```

## onie-bisdn-upgrade

The script `onie-bisdn-upgrade` enables you to upgrade a running BISDN Linux to a newer image. The corresponding man pages and usage help can be displayed like this:

```
man onie-bisdn-upgrade
onie-bisdn-upgrade -h
```

This shows an example usage:

```
onie-bisdn-upgrade http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin
```

**Note**: All data is deleted during the upgrade process except for configuration files in /etc/systemd/network/ that apply on interfaces named `enp*`.
{: .label .label-yellow }

## onie-bisdn-rescue

The script `onie-bisdn-rescue` enables you to boot into ONIE-rescue mode from the BISDN Linux shell. The corresponding man pages and usage help can be displayed like this:

```
man onie-bisdn-rescue
onie-bisdn-rescue -h
```

The ONIE-rescue shell provides troubleshooting. More information can be found here: [ONIE-rescue mode](https://opencomputeproject.github.io/onie/design-spec/nos_interface.html#rescue-and-recovery). 
