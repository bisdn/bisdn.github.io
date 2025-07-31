---
title: Basebox
nav_order: 12
---

# Developer Guide

## BISDN Linux build system

BISDN Linux is based on the [Yocto Buildsystem], using a the [repo tool] for
setting up its source tree.

For information on how to build BISN Linux, see the [BISDN Linux](https://github.com/bisdn/bisdn-linux#readme)
repository.

For information on how to work with Yocto, see the [Yocto Documentation](https://docs.yoctoproject.org/4.0.10/).

## Adding new platform support for ONL supported platforms

To add support for a plaform, you need add changes to four places:

* Enable the platform for ONL so its ONL platform support gets built
* Add a platform init script to platform-onl-init based on the ONL init code
* Add a configuration file for the installer
* Add configuration files to ofdpa-platform

### Enabling the platform for ONL

First, you will need to determine the ONIE platform name. To do that, enter the
ONIE shell, and issue the following command:

```
onie-sysinfo -p
```

This will print the platform name according to ONIE, which is used for
identifying the running platform by the installer.

While at it, also write down the ONIE version, as you will need that information
later.

In the best case, all you then need is to extend [`ONL_PLATFORM_SUPPORT`](https://github.com/bisdn/meta-open-network-linux/blob/main/conf/machine/generic-x86-64.conf#L21)
with this ONIE platform name, and add the platform kernel modules to [`MACHINE_EXTRA_RDEPENDS`](https://github.com/bisdn/meta-open-network-linux/blob/main/conf/machine/generic-x86-64.conf#L35).

Depending on the platform, you may also need to extend [`ONL_MODULE_VENDORS`](https://github.com/bisdn/meta-open-network-linux/blob/main/conf/machine/generic-x86-64.conf#L33),
as some vendors share kernel modules across platforms.

Likely you will encounter build issues due to kernel modules written for
older kernels, or the platform code having issues newer GCC versions complain
about.

The following section will give an overview how to add patches to fix these
issues.

### Patching ONL

Start by checking out [OpenNetworkLinux](github.com/opencomputeproject/OpenNetworkLinux) based on [the revision mentioned in the recipe](https://github.com/bisdn/meta-open-network-linux/blob/main/recipes-extended/onl/onl_git.bb#L11).

Then locate the platform support directory for the platform you want add. You
can usually find it at

```
packages/platforms/<vendor>/<arch>/<short-name>
```

For some of the common issues we [provide coccinelle semantic patches](https://github.com/bisdn/meta-open-network-linux/tree/main/scripts/coccinelle)
which can fix up various code issues automatically.

You can apply them via

```
spatch --sp-file .cocci --in-place --dir packages/platforms/path/to/platform
```

Then, create a patch for the code changes by first committing them, adding a [nice commit message](https://www.kernel.org/doc/html/v4.10/process/submitting-patches.html#describe-your-changes)
(don't forget to sign them off!), then add them to the ONL recipe, like [here](https://github.com/bisdn/meta-open-network-linux/commit/f1546428eac52b2391ad496ffa3f0f71b35863fa).

If you encounter additional issues, fix them similarly with appropriate patches.

It is also a good idea to check the [open pull requests at ONL](https://github.com/opencomputeproject/OpenNetworkLinux/pulls)
for any pending updates or fixes for the platform you want to add.

### Adding a platform init script

ONL uses a python 2 based initialization code, but python 2 is EOL, so the
platform init code would need to be updated, or python 2 provided in our images.

Since shipping python 2 would be potential security issue, and updating the ONL
code for python 3 would be a huge task, we chose to instead rewrite the
individual platform init codes to simple bash scripts.

The package providing them is [platform-onl-init](https://github.com/bisdn/meta-open-network-linux/tree/main/recipes-core/platform-onl-init), which automatically calls a
script named after its ONL platform name, which is similar to the above ONIE
platform name, except it replaces all underscores with dashes.

First, locate the platform init code for your platform. It is usually found at

```
packages/platforms/path/to/platform/platform-config/r0/src/python/<platform>/__init__.py
```

Then take the ONL platform init code and transcribe it to bash. There are a few
things to look out for:

We do not load any of the I<sup>2</sup>C bus drivers on x86 platforms automatically, so you
will need to manually do that in your script. Due to the way the ONL platform
code works, the load order is important, as it influences the numbers assigned
to the buses.

The most common way for that is to start the code with the following:

```
# make sure i2c-i801 is present
modprobe i2c-i801
wait_for_file /sys/bus/i2c/devices/i2c-0

# load modules
modprobe i2c-ismt
```

After that you can add the platform init code following what ONL does.

We do have some [helper functions](https://github.com/bisdn/meta-open-network-linux/blob/main/recipes-core/platform-onl-init/files/platform-onl-init.sh) for reducing the verbosity needed for the
bash code.

`create_i2c_dev` can be used as replacement for `new_i2c_device`. It takes the
same arguments. E.g.

```
self.new_i2c_device('pca9548', 0x77, 1)
```

becomes

```
create_i2c_dev 'pca9548' 0x77 1
```

For initializing optoe devices, there is the helper `add_port` which can be used
to easily create the device and set its name to port\<portnum\>.

E.g.

```
for port in range(49, 53):
    self.new_i2c_device('optoe2', 0x50, port-31)
    subprocess.call('echo port%d > /sys/bus/i2c/devices/%d-0050/port_name' % (port, port-31), shell=True)
```

can be rewritten as

```
for port in {49..52}; do
	add_port 'optoe2' $port $((port - 31))
done
```

Note that the limit in ranges is inclusive in bash, but exclusive in python, so
you need to substract one.

As we are adding devices for the (Q)SFP ports, we do not need to pass any
addresses, as the SFF standards mandate the address to 0xA0 (0x50), so
`add_port` will automatically use this address.

### Enabling the platform in the installer

The installer needs to know it supports the platform, and needs to know a few
things about that.

For that you can transcribe the platform information found in ONL at as an
appropriate configuration file at

```
packages/platforms/path/to/platform/platform-config/r0/src/lib/<platform-name>.yml
```

The file should look like this:

```
######################################################################
#
# platform-config for AS5835
#
######################################################################

x86-64-accton-as5835-54x-r0:

  grub:

    serial: >-
      --port=0x3f8
      --speed=115200
      --word=8
      --parity=no
      --stop=1

    kernel:
      <<: *kernel-4-14

    args: >-
      nopat
      console=ttyS0,115200n8
      intel_iommu=off

  ##network
  ##  interfaces:
  ##    ma1:
  ##      name: ~
  ##      syspath: pci0000:00/0000:00:14.0
```

Using this, create a new file named `platform.conf` in a directory named like the
ONIE machine name [here](https://github.com/bisdn/meta-switch/tree/main/scripts/installer/machine).

The contents of the platform.conf should look like this:

```
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"
GRUB_SERIAL_COMMAND="serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1"
EXTRA_CMDLINE_LINUX="nopat intel_iommu=off"
```

### Adding ASIC configuration to ofdpa-platform

OF-DPA takes its switch configuration from the [ofdpa-platform](https://github.com/bisdn/meta-ofdpa/tree/main/recipes-ofdpa/ofdpa/ofdpa-platform) package. There it
loads its configuration based on the [ONL platform name](https://github.com/bisdn/meta-ofdpa/tree/main/recipes-ofdpa/ofdpa/ofdpa-platform/platform). See the README.md in the repository for a
detailed description of its format and expected file names and locations.

For platforms supported by [SONIC](https://github.com/sonic-net/sonic-buildimage/tree/master/device), you may be able to use the configuration from
there, else you will need to request one from the device manufacturer.

If the device is supported by SONIC, you can use the device's
`led_proc_init.soc` as `rc.soc`, and `<Device-Name>/<something>.bcm` as
 `config.bcm`.

Be aware that using also taking over the `custom_led.bin` used by Trident 3
devices is currently not possible due to unresolved licensing issues, so you
may need to uncomment the command for loading it in the `rc.soc`:

```
# m0 load 0 0x3800 /usr/share/ofdpa/platform/x86-64-accton-as5835-54x-r0/custom_led.bin
```

### Testing the changes

Once you are done with all steps, you are now ready for testing your changes.
After building an image with your changes, you should be now able to install it
via ONIE.

Once it successfully installed, check that it works as expected:

* Does `onlpdump` show all expected information, without any errors?
* Are all port interfaces present?
* Do the port interfaces come up when you connect a cable and set the up?
* Do the port interfaces transmit packets when up?
* Do the port LEDs light up as expected?

Play around with it, and maybe follow some of the configuration examples in this
documentation.

### Update the documentation

To tell the world that the new model is now supported, the documentation needs
to be updated at several places:

* Add the previously written down ONIE version to the [supported ONIE versions](getting_started/install_onie.md#supported-onie-versions).
* Update the [OF-DPA Table sizes table](platform_configuration/ofdpa_table_sizes.md#resulting-table-sizes)
  with the new model.
* Finally, add the switch model to the [List of supported platforms](download_images.md).

### Create pull requests for your changes

Finally, after you have verified the new platform works, you are now ready to
create pull requests for your changes.

Please make sure to mark any dependencies between them, and describe your
changes and testing method/results properly.

You may need to update the pull requests based on review comments. In this case,
please do not close them and create new ones, but rebase and squash in fixes
into the commits as necessary.

Note that the documentation changes will likely be merged only when the release
containing the support is released.
