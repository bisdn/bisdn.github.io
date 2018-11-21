# Install BISDN Linux

Installing BISDN Linux on a whitebox switch can be done via the [ONIE][ONIE] installer. This page shows how to connect to the switch and guides through the installation process.

## Connect to the switch console

Connect the `CONSOLE` port of the switch to a computer of your choice. We recommend using the tool [kermit][kermit]. On a Linux machine install ckermit, edit a file named `.kermrc` and put in your config with the used line port.

Example of `.kermrc`:

```
set line /dev/ttyUSB0
set speed 115200
set carrier-watch off
set flow-control xon/xoff
connect
```

On the Linux machine run `kermit`. It will connect to the console of the attached switch. Once the switch is powered on you should see the console output.

## Install BISDN Linux via ONIE

Power on the switch. During boot, press `DEL` key to enter the boot menu (there is a prompt for that). Select ONIE to get into the ONIE menu or BISDN Linux to start BISDN Linux (this option is only available after it has been installed).

Select `ONIE: Install OS` in the ONIE menu to install a switch image. To remove the image select `ONIE: Uninstall OS`.

### Get the image via the CLI

Select `ONIE: Rescue` to get to the cli. Install the image via a cli command as in the example below. Images can be found [here][image-repository]

```
onie-nos-install http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin
```

More information about the ONIE cli can be found [here](https://opencomputeproject.github.io/onie/cli/index.html#onie-nos-install).

### Get the image via DHCP option 60
Connect the management port to a DHCP server of your choice. The DHCP server uses "Vendor Class Identifier – Option 60" to tell the switch the URL of the image.

Example of dnsmasq config:

```
dhcp-vendorclass=set:ag7648,"onie_vendor:x86_64-ag7648-r0"
dhcp-option=tag:ag7648,114,"http://example_webserver.com/onie/onie-bisdn-agema-ag7648.bin"
```

In the example "example_webserver.com" is the server that must host the BISDN Linux image, the location of the actual file is then managed by the webserver (out of scope here). Any switch of type `ag7648` will be given the link and is then able to fetch the said image.

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

After successful installation the switch will reboot itself. Once it is booted you should see a similar message:

```
BISDN Linux 1.0.0 agema-ag7648 ttyUSB0

agema-ag7648 login:
```

Login with username `root`. You should see the console of BISDN Linux. See the systeminformation via [dmidecode][dmidecode].

How to use the console and start services, please see the next section.

## Additional resources 
* [ONIE][ONIE]
* [kermit website][kermit]
* [dmidecode][dmidecode]
* [image-repository][image-repository]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[kermit]: http://www.kermitproject.org/ (kermit website)
[ONIE]: http://www.onie.org/ (ONIE website)
[dmidecode]: https://wiki.ubuntuusers.de/dmidecode/ (dmidecode website)
[image-repository]: https//repo.bisdn.de/ftp/pub/ (BISDN image repository)
