---
date: '2020-01-07T16:07:30.187Z'
docname: setup/known_issues
images: {}
path: /setup-known-issues
title: Known issues
nav_exclude: true
---

# Known issues

## Table size differences

There might be discrepancies in the maximum number of entries in the unicast routing table (30) announced by [of-dpa](https://github.com/Broadcom-Switch/of-dpa) and how many it accepts.

The [AG8032](https://agema.deltaww.com/UserFiles/files/AG8032%20Datasheet.pdf) switch announces a maximum of 24k entries for the unicast routing table (30), however [of-dpa](https://github.com/Broadcom-Switch/of-dpa) only takes 8k host routes and 8k network routes.

The [AG7648](https://agema.deltaww.com/product-info.php?id=29) switch announces a maximum of 32k entries for the unicast routing table(30) and [of-dpa](https://github.com/Broadcom-Switch/of-dpa) takes 16k host routes and 16k network routes.

## Linux namespaces

baseboxd is not compatible with [Linux namespaces](http://man7.org/linux/man-pages/man8/ip-netns.8.html). Moving basebox’s interfaces to a namespace will duplicate them.

## Upgrade of BISDN Linux via onie-bisdn-upgrade

The script onie-bisdn-upgrade allows to use static IP configuration instead of DHCP. However, using the current ONIE installer, there is no route set towards the gateway, so images outside the configured network or, when using the “current” option, outside the switch management network (‘enp0s20f0’) can not be pulled and installed automatically.

Also note, that when DHCP is used an image provided by the DHCP server (option 60) will have priority over the image specified as parameter of the onie-bisdn-upgrade script.
