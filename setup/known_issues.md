# Known issues

## Linux namespaces

baseboxd is not compatible with [Linux namesspaces][netns]. Moving basebox's interfaces to a namespace will duplicate them.

## Additional resources
* [netns man-page][netns]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[netns]: http://man7.org/linux/man-pages/man8/ip-netns.8.html (netns man-page)
