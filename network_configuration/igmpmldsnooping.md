---
title: IMGP/MLD Snooping
parent: Network Configuration
---

# IGMP/MLD Snooping

BISDN Linux itself is capable of acting as a layer 2 multicast switch and with the help of frr can also be turned into a full fledged multicast router.

In multicast switches and routers, the multicast group membership is managed by utilising the Internet Group Management Protocol (IGMP) or Multicast Listener Discovery (MLD). Both protocols report the interest of a host to receive a data stream, IGMP for IPv4 and MLD for IPv6 traffic. IGMP and MLD snooping is a technique that allows multicast switches to maintain a map of which links need to receive IP multicast transmissions.

## Linux Configuration

Linux implements IGMP/MLD snooping at the kernel level, and baseboxd listens for the changes (netlink messages) to the bridge multicast database triggered by IGMP/MLD snooping.

To enable multicast switching in BISDN Linux, we first have to connect the ports that will have multicast senders or receivers with a bridge. The bridge device will then receive the IGMP/MLD notifications and baseboxd will configure the new entries on the ASIC.

We first create the bridge with some ports attached like described above (for instructions on how to do that, please refer to [VLAN Bridging](network_configuration/vlan_bridging.html#vlan-bridging-8021q):

```
7: swbridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether c6:65:bb:67:62:64 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535 
    bridge forward_delay 1500 hello_time 200 max_age 2000 ageing_time 30000 stp_state 0 priority 32768 vlan_filtering 1 vlan_protocol 802.1Q bridge_id 8000.c6:65:bb:67:62:64 designated_root 8000.c6:65:bb:67:62:64 root_port 0 root_path_cost 0 topology_change 0 topology_change_detected 0 hello_timer    0.00 tcn_timer    0.00 topology_change_timer    0.00 gc_timer   66.56 vlan_default_pvid 1 vlan_stats_enabled 0 group_fwd_mask 0 group_address 01:80:c2:00:00:00 mcast_snooping 1 mcast_router 1 mcast_query_use_ifaddr 0 mcast_querier 1 mcast_hash_elasticity 16 mcast_hash_max 4096 mcast_last_member_count 2 mcast_startup_query_count 2
```

You can also check which links are attached to the bridge like this:

```
:~$ bridge link
9: port2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master swbridge state forwarding priority 32 cost 100 
14: port7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master swbridge state forwarding priority 32 cost 100 
15: port8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master swbridge state forwarding priority 32 cost 100 
```

After this initial setup the bridge multicast database should look like this:

```
:~$ bridge mdb
7: swbridge  port7     ff02::1:ff62:d400  temp  vid 1
7: swbridge  port8     ff02::1:ff62:d401  temp  vid 1
7: swbridge  swbridge  ff02::1:3  temp  vid 1
7: swbridge  swbridge  ff02::1:ff00:0  temp  vid 1
7: swbridge  swbridge  ff02::2  temp  vid 1
7: swbridge  swbridge  ff02::6a  temp  vid 1
7: swbridge  swbridge  ff02::1:ff67:6264  temp  vid 1
```

If a host if attached to port7, and it is interested in receiving a certain multicast stream for the multicast group `225.1.2.3`, it will send an IGMP notification to the switch. Via IGMP snooping, Linux then ensures that the multicast database is correctly updated and the new entry is visible:

```
:~$ bridge mdb
7: swbridge  port7     225.1.2.3  temp  vid 1
7: swbridge  port7     ff02::1:ff62:d400  temp  vid 1
7: swbridge  port8     ff02::1:ff62:d401  temp  vid 1
7: swbridge  swbridge  ff02::1:3  temp  vid 1
7: swbridge  swbridge  ff02::1:ff00:0  temp  vid 1
7: swbridge  swbridge  ff02::2  temp  vid 1
7: swbridge  swbridge  ff02::6a  temp  vid 1
7: swbridge  swbridge  ff02::1:ff67:6264  temp  vid 1
```
## Advanced configurations

When using iproute2 instead of systemd-networkd to create a bridge, there are a couple of additional options for more fine grained configuration that are worth noting in this context.

We can use these specific multicast configurations to control parameters like snooping or IGMP/MLD protocol versions. The following options are truncated and meant as an example, please consult [man ip-link](https://www.systutorials.com/docs/linux/man/8-ip-link/) for more information.

```
OPTIONS:
 mcast_snooping 
 mcast_router 
 mcast_querier 
 mcast_igmp_version IGMP_VERSION
 mcast_mld_version MLD_VERSION
```
