---
title: switch_tcpdump
parent: Tools
nav_order: 2
---

# switch_tcpdump

## Traffic capture with tcpdump

The `switch_tcpdump` tool allows users to capture traffic seen in BISDN Linux on any switch port network interface created by `baseboxd`, e.g. `port1`.

The captured traffic includes all ingress traffic on the specified port and all traffic sent from BISDN Linux through the port. It does not capture egress traffic that is redirected within the switch ASIC to the specified port without passing through the Linux kernel.

Internally, this is done by adding an ACL table entry matching on the desired port with the [ACL table entry management tool](#acl-table-entry-management) and sending its traffic to controller, capturing traffic with `tcpdump`. Once the capture is done, the ACL table entry is removed again.

Since captured traffic is sent to controller, matched packets are not routed directly through the ASIC. A substantial performance penalty is expected when capturing traffic, as packets are processed by the switch CPU instead of the ASIC.

As the `switch_tcpdump` tool is a wrapper around `tcpdump`, its usage and behavior should be familiar to users with experience in using `tcpdump`. However, there are a few additional options that are specific to the `switch_tcpdump` tool:

- The `--inPort` argument is the only mandatory option. It specifies the port where the traffic will be captured. The tool will create an ACL table entry to match the ingress traffic on the specified port and send it to the controller.
- The `--filePath` option specifies the file where the captured traffic will be written. It differs from `tcpdump`'s `-w` option  in that it limits the file size to 100 MB (or the value specified by the `--maxSize` option).
- The `--maxSize` option specifies the maximum size of the capture file given with `--filePath`. If the file reaches this size, the capture will stop. If `--maxSize` is not specified, the default maximum size of 100 MB will be used.
- The `--timeout` option specifies the duration of the capture in seconds. If the `--timeout` option is not specified, the capture will continue until the user interrupts it (e.g. by pressing CTRL-C).

The remaining options are passed directly to `tcpdump`, so its options can be used with `switch_tcpdump`. Filtering captured traffic is possible using [the filter syntax of `tcpdump`](https://www.tcpdump.org/manpages/pcap-filter.7.html).

See also the man page of `switch_tcpdump` for more information.

**Note**: This tool needs to be executed with super user privileges.
{: .label .label-yellow }


## Examples

Capturing traffic on `port2` until user interruption (e.g. until the user presses CTRL-C):

```
switch_tcpdump --inPort port2
```

Capture ICMP traffic on `port2` and write the output to `icmp_traffic.pcap` until this file reaches 200 MB in size:

```
switch_tcpdump --inPort port2 --filePath icmp_traffic.pcap --maxSize 200 icmp
```

Capture TCP traffic (the optional `--filters` omitted in this example) on `port2` and write the output to `tcp_traffic.pcap` during 10 seconds (or until the default maxSize of 100 MB is reached):

```
switch_tcpdump --inPort port2 --filePath tcp_traffic.pcap --timeout 10 tcp
```
