---
title: Install BISDN Linux
parent: Getting Started
nav_order: 3
---

# Install BISDN Linux

Installing BISDN Linux on a whitebox switch can be done via the ONIE installer.
This section shows how to connect to the switch and guides through the
installation process.

**WARNING**: Installing a BISDN Linux image requires a stable internet
connection. To do this, please attach a network cable to the Management port of
your switch.
{: .label .label-red }

## Install BISDN Linux via ONIE

The recommended switch image installation is done via ONIE, a tool that allows
installation of Network Operating Systems on bare metal servers. This will
prevent issues due to the bootloader difference between x86 and ARM platforms,
where GRUB and coreboot are used, respectively.

On switches using GRUB bootloader:

Select `ONIE: Install OS` in the ONIE menu to install a switch image. To remove
the image, select `ONIE: Uninstall OS`.

On switches using U-Boot bootloader:

Interrupt the U-Boot boot countdown by pressing any key and enter

```
setenv onie_boot_reason install && boot
```

to install a switch image. To remove the image, enter
```
run onie_uninstall
```

The BISDN image can be installed either via the [ONIE CLI](#get-the-image-via-the-cli)
or through a [DHCP server](#get-the-image-via-dhcp-option-60). Both methods are
described below.

**Note**: It is recommended to uninstall any existing OS before installing
BISDN Linux.
{: .label .label-yellow }

### Get the image via the CLI

On switches using GRUB bootloader:

Enter the ONIE boot menu then select `ONIE: Rescue` to get into the ONIE CLI.

On switches using U-Boot bootloader:

Interrupt the U-Boot boot countdown by pressing any key and enter

```
run onie_rescue
```

to get into the ONIE CLI.

Install the image via a CLI command as in the example below. All images are
hosted in our [image repo](http://repo.bisdn.de/) while released images can be
directly installed from [here](http://repo.bisdn.de/pub/onie/).

This example installs BISDN Linux v3.3.0 for the AG7648 platform:
```
onie-nos-install http://repo.bisdn.de/pub/onie/agema-ag7648/onie-bisdn-agema-ag7648-v3.3.0.bin
```

**Note**: The ONIE CLI command can only process http URLs.
{: .label .label-yellow }

More information about the ONIE CLI command can be found [here](https://opencomputeproject.github.io/onie/cli/index.html#onie-nos-install).

### Default Installer Files

**WARNING** Setting a default configuration will reset the file system to the
initial state. Only use this if you are prepared to lose all modifications of
your current BISDN Linux installation.
{: .label .label-red }

BISDN Linux by default provides no network configuration for the switch ports.
To allow a more switch like default configuration, it is possible to use the
environment variable `BISDN_DEFAULT_CONFIG` while installing BISDN Linux to
provide a default network configuration.

```
BISDN_DEFAULT_CONFIG="simple-l2-bridge" onie-nos-install http://repo.bisdn.de/pub/onie/generic-x86-64/onie-bisdn-generic-x86-64-v5.1.X.bin
```

The following table shows the supported configuration for
`BISDN_DEFAULT_CONFIG` and the expected outcome.

|`BISDN_DEFAULT_CONFIG` Value|Outcome                                                                                        |Default|
|----------------------------|-----------------------------------------------------------------------------------------------|-------|
|(Empty)                     |Use previous installation configuration                                                        |Y      |
|`none`                      |Removes existing configuration and initializes the switch with all ports disabled              |       |
|`simple-l2-bridge`          |Removes existing configuration and initializes the switch to forward traffic between all ports |       |

### Get the image via DHCP option 60

Connect the management port to a DHCP server of your choice. The DHCP server
uses “Vendor Class Identifier – Option 60” to tell the switch the URL of the
image.

Example of dnsmasq configuration:

```
dhcp-vendorclass=set:ag7648,"onie_vendor:x86_64-ag7648-r0"
dhcp-option=tag:ag7648,114,"http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin"
```

In the example “example_webserver.com” is the server that must host the BISDN
Linux image, the location of the actual file is then managed by the webserver
(out of scope here). Any switch of type ag7648 will be given the link and is
then able to fetch the listed image.

You should see a similar log on the system:

```
ONIE: Using DHCPv4 addr: eth0: 172.16.253.110 / 255.255.255.0
ONIE: Starting ONIE Service Discovery
Info: Fetching http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin ...
ONIE: Executing installer: http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin
Verifying image checksum ... OK.
Preparing image archive ... OK.
Demo Installer: platform: x86_64-agema_ag7648-r0
```

### Post installation

After successful installation the switch will reboot itself. Once it has
finished booting you should see a similar message:

```
BISDN Linux 3.3.0 agema-ag7648 ttyUSB0

agema-ag7648 login:
```

## Backup files/folders across installations

By default BISDN Linux keeps files/directories based on packages' configuration
file lists (located at `/var/lib/opkg/info/*.conffiles`) and the list in
`/etc/default/system-backup.txt`.

To back up additional files when installing a new BISDN Linux version, use the
`/etc/default/user-backup.txt` file. This `user-backup.txt` file supports a
simple syntax to configure a custom list of files to keep during system
upgrade:

- absolute paths to files or directories to keep:
e.g. "/etc/default/user-backup.txt"

- prefixed paths with a "-" for configuration files to NOT keep:
e.g. "-/etc/hostname"

- comments prefixed with #.
