# Known issues

## Table size differences

There might be discrepancies in the maximum number of entries in the unicast routing table (30) announced by [of-dpa][ofdpa] and how many it accepts. 

The [AG8032][ag8032] switch announces a maximum of 24k entries for the unicast routing table (30), however [of-dpa][ofdpa] only takes 8k host routes and 8k network routes.

The [AG7648][ag7648] switch announces a maximum of 32k entries for the unicast routing table(30) and [of-dpa][ofdpa] takes 16k host routes and 16k network routes.

## Linux namespaces

baseboxd is not compatible with [Linux namesspaces][netns]. Moving basebox's interfaces to a namespace will duplicate them.

## Additional resources
* [of-dpa][ofpda]
* [netns man-page][netns]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[ag8032]: https://agema.deltaww.com/UserFiles/files/AG8032%20Datasheet.pdf
[ag7648]: https://agema.deltaww.com/product-info.php?id=29
[ofdpa]: https://github.com/Broadcom-Switch/of-dpa

[netns]: http://man7.org/linux/man-pages/man8/ip-netns.8.html (netns man-page)
