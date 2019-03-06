# Known issues

## Table size differences

There might be discrepancies in the maximum number of entries in the unicast routing table (30) announced by [of-dpa][ofdpa] and how many it accepts. 

The [AG8032][ag8032] switch announces a maximum of 24k entries for the unicast routing table (30), however [of-dpa][ofdpa] only takes 8k host routes and 8k network routes.

The [AG7648][ag7648] switch announces a maximum of 32k entries for the unicast routing table(30) and [of-dpa][ofdpa] takes 16k host routes and 16k network routes.

## Linux namespaces

baseboxd is not compatible with [Linux namespaces][netns]. Moving basebox's interfaces to a namespace will duplicate them.

## Upgrade of BISDN Linux via onie-bisdn-upgrade

The script `onie-bisdn-upgrade` allows to use static IP configuration instead of DHCP. However, using the current ONIE installer, there is no route set towards the gateway, so images outside the configured network or, when using the "current" option, outside the switch management network ('enp0s20f0') can not be pulled and installed automatically.

Also note, that when DHCP is used an image provided by the DHCP server (option 60) will have priority over the image specified as parameter of the onie-bisdn-upgrade script.

## Additional resources
* [of-dpa][ofdpa]
* [netns man-page][netns]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[ag8032]: https://agema.deltaww.com/UserFiles/files/AG8032%20Datasheet.pdf
[ag7648]: https://agema.deltaww.com/product-info.php?id=29
[ofdpa]: https://github.com/Broadcom-Switch/of-dpa

[netns]: http://man7.org/linux/man-pages/man8/ip-netns.8.html (netns man-page)
