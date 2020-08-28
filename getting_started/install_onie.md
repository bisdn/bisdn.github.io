---
title: Install ONIE
parent: Getting Started
nav_order: 2
---

## Install ONIE 

Check the current ONIE version of your switch by executing the following command in e.g. the ONIE-rescue shell:

```
onie-sysinfo -v
```

If your switch has the supported ONIE preinstalled you can skip this part and [Install BISDN Linux](/getting_started/install_bisdn_linux.md) right away. In the other case you can either install a complete ONIE or upgrade an existing one.

### Supported ONIE versions

Only the following ONIE versions are tested and supported. Installation on other version may not work as expected.

| Device                 | Bootloader | ONIE version    |
|------------------------|------------|-----------------|
| Delta AG5648           | GRUB       |[V1.00](https://github.com/DeltaProducts/ag5648/tree/master/onie_image/) |
| Delta AG7648           | GRUB       |[2017.08.01-V1.12](https://github.com/DeltaProducts/AG7648/tree/master/onie_image/) (Build date 20181109) |
| Edgecore AS4610-30T/P  | U-Boot     |[2016.05.00.04](https://support.edge-core.com/hc/en-us/articles/360035081033-AS4610-ONIE-v2016-05-00-04)<sup>1</sup> |
| Edgecore AS4610-54T/P  | U-Boot     |[2016.05.00.04](https://support.edge-core.com/hc/en-us/articles/360033232494-AS4610-ONIE-v2016-05-00-04)<sup>1</sup> |

<sup>1</sup> Edgecore support account required

### Install ONIE

Prepare a bootable USB device and copy the proper ONIE image to it. One way is to download the .iso file given by the links above. Copy the file to the USB device like in the example below.


This example copies the .iso of the ONIE installer for AG7648 to the USB device on sdb:
```
sudo dd if=20181109-onie-recovery-x86_64-delta_ag7648-r0.iso of=/dev/sdb bs=10M
sync
```

Attach the USB device to your switch and reboot it. Enter the ONIE boot menu then press `c' to get into the grub CLI. Enter the following commands to boot from a USB device.

```
set root=(hd1)
chainloader +1
boot
```

Then select `ONIE: Embed ONIE` and the switch is going to install ONIE from the USB device.

### Update ONIE

Reboot the switch.

On switches using GRUB bootloader:

Enter the ONIE boot menu then select `ONIE: Rescue` to get into the ONIE CLI.

On switches using U-Boot bootloader:

Interrupt the U-Boot boot countdown by pressing any key and enter

```
run onie_rescue
```

to get into the ONIE CLI.

Download the .bin file given by the links above and put it onto an http server that is reachable by the switch. Start the update via the CLI command `onie-self-update` as shown in the example below.

```
onie-self-update -v http://local-http-server/onie-updater
```

**Note**: The ONIE CLI command can only process http URLs`
{: .label .label-yellow }

More information about the ONIE CLI command can be found [here](https://opencomputeproject.github.io/onie/cli/index.html#onie-self-update).

