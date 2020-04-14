---
title: OF-DPA Client Tools
parent: Tools
nav_order: 2
---

# OF-DPA Client Tools

These tools enable you to interact with the OF-DPA layer and can be used to cross-check controller behavior and configuration. The following commands can be used to show the flow, group tables and ports, respectively:

```
client_flowtable_dump
client_grouptable_dump
client_port_table_dump
```

## ACL table entry management

The access-control list (ACL) table, i.e. table 60, is internally used by baseboxd to handle special types of traffic, such as flooded ARP or LLDP packets.
However, this table supports OpenFlow byte and packet counters for each existing table entry (contrary to the other OFDPA tables, where those are not available). These statistics can be seen by using the `-s` flag in the `client_flowtable_dump` tool:

```
client_flowtable_dump -s 60
```

The visualization of these statistics enables users to monitor network traffic by creating fine-grained OpenFlow match-based flow entries.
These table entries can be installed without any additional action on matched packets, thus being passively used for statistical purposes.

The `ofdpa_acl_flow_cli.py` tool can be used to manage the traffic monitoring ACL table entries. This tool receives as command line arguments the flow match fields and respective values, alongside with the add/delete operation identifier, `-a/--add` and `-d/--delete`, respectively.
A list of all the supported fields can be consulted through the `--help` option:

```
ofdpa_acl_flow_cli.py --help
```

To easily identify the installed flows, the `cookie` attribute can be set on each flow. This allows the deletion of table entries by only specifying its cookie identifier (instead of all matching attributes).
Yet, this attribute needs to be uniquely set for each flow, as it will not be possible to delete two or more flows with the identifier.

Each packet can only be matched on one flow entry, so the table flow rules need to be correctly defined. In addition, when adding/deleting table entries, the [OFDPA table type pattern (TTP) guidelines](https://github.com/Broadcom-Switch/of-dpa/blob/master/OFDPAS-ETP100-R.pdf) must be followed, as previously mentioned in the [Basebox introductory section](/basebox.html#openflow).
For example, adding the following entry will result an error:

```
ofdpa_acl_flow_cli.py -a --ipProto 0x01
```

In this case, since the L2 etherType is not defined, it is not possible to match L3 fields in a flow entry. Adding the IPv4 etherType in the match, for example, will make the flow entry valid:

```
ofdpa_acl_flow_cli.py -a --etherType 0x0800 --ipProto 0x01
```

### Examples
#### Adding flows

```
# Ingress traffic on port 7. The ingress port mask must be set, otherwise this field is seen as a wildcard.
ofdpa_acl_flow_cli.py -a --inPort 7 --inPortMask 0xffffffff

# IPv4 traffic from the 192.168.1.0/24 subnet. Flow cookie is set to 10000
ofdpa_acl_flow_cli.py -a --etherType 0x800 --sourceIp4 192.168.1.0 --sourceIp4Mask 255.255.255.0 --cookie 10000

# IPv6 UDP traffic with destination port 5000 from VLAN 10 with an exact VLAN mask. 
# Note the VLAN_VID_PRESENT flag (0x1000) on both VLAN ID/mask values, according to the OFDPA specification. 
# Cookie is set to 10001.
ofdpa_acl_flow_cli.py -a --etherType 0x86dd --ipProto 0x11 --destL4Port 5000 --vlanId 0x100a --vlanIdMask 0x1fff --cookie 10001

```

#### Deleting flows

The following commands delete the previously created flows:

```
ofdpa_acl_flow_cli.py -d --inPort 7 --inPortMask 0xffffffff
ofdpa_acl_flow_cli.py -d --cookie 10000
ofdpa_acl_flow_cli.py -d --cookie 10001
```


### Troubleshooting

Failure on following the TTP guidelines will result in error messages in the `ofdpa_acl_flow_cli.py` tool.
To troubleshoot errors on flow operations, the verbose setting from the `OFDB` module from `ofdpa` must be increased. This is done by editing the `OPTIONS` variable in the `/etc/default/ofdpa` file:

```
### Configuration options for ofdpa
#
# Set the component for debugging (can be added multiple times),
# valid components are:
#        1 = API
#        2 = Mapping
#        3 = RPC
#        4 = OFDB
#        5 = Datapath
#        6 = G8131
#        7 = Y1731
# e.g. (API and Mapping):
# -c 1 -c 2
#
# debug level 0..4 (all components)
# -d 2
#
# example:
# OPTIONS="-c 1 -c 2 -d 2"
OPTIONS="-c 4 -d 4"
```

These changes are applied by restarting the `ofdpa` service:

```
sudo systemctl restart ofdpa
```

With the new verbose option, error messages regarding the creation of new flows can be followed using `journalctl`, e.g.:

```
sudo journalctl -fu ofdpa
Apr 14 12:37:59 agema-ag7648 ofdpa[10452]: ofdbFlowPolicyAclEntryValidate: Invalid ethertype for IPv6 match fields.
```
