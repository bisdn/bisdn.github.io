# CAWR
## Introduction
CAWR – which stands for Capability AWare Routing – is a supplemental intermediate OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. This giant switch integrates smoothly with baseboxd and lets you scale your effective switch capacity. CAWR implements multi-path routing and supports multichassis link aggregation (MLAG). Hence, it combines a scalable data center switching solution with high availability.

## Architecture
CAWR, as a secondary controller, is placed in between baseboxd and the physical switches. Both, its northbound and southbound interfaces, are [OpenFlow][of] and following the [OF-DPA][ofdpa] standard.

```text
/CAWR architecture/

                            +----------+            +
                            | baseboxd |            |
              +             +--+---+---+            |
logical ports:|             |A | B | C |            |
              +             +--+-^-+---+            | control
                                 |                  | plane
                              +--v---+              |
                        +-----> CAWR <-----+        |
                        |     +------+     |        +
                        |                  |
                        |                  |
                  +-----v----+        +----v-----+  +
                  | switch X |        | switch Y |  | data
               +  +----------+        +----------+  | plane
physical ports:|  |A1| B1 |C1|        |A2| B2 |C2|  |
               +  +----------+        +----------+  +

```

CAWR implements all the algorithms supporting its internal workflow, while employing the [ROFL][rofl] library to interact with OpenFlow traffic.

## Failover
CAWR was designed to handle multi-switch configurations. The current version supports up to two switches.
A host can be connected to each of the switches by a pair of interfaces that have bond mode configured.
CAWR then takes care of routing the layer 2 traffic across the physical network and provides failover mechanism to deliver uninterrupted operation even if one of the switches or one of the bond ports goes down or when a cable is broken.
To provide failover, CAWR uses specific VLAN IDs that can be configured in the "cawr_config.yaml". Failover VLAN IDs must not be used to configure tenant networks in etcd.

```text
/server connectivity using bond mode/

          +----------+            +
          | baseboxd |            | control
          +----------+            | plane
          |   CAWR   |            |
     +--->+----------+<---+       +
     |                    |
     |                    |
     |                    |
+----v-----+        +-----v----+  +
| switch a <--------> switch b |  | data
+-----^----+        +----^-----+  | plane
      |                  |        |
      |    +--------+    |        |
      |    | server |    |        |
      |    +--------+    |        |
      |    |  bond  |    |        |
      |    +--------+    |        |
      |    |P1 || P2|    |        |
      |    +-+----+-+    |        |
      |      |    |      |        |
      +------+    +------+        +
```

## Topology discovery (LACP and LLDP)
CAWR adds LACP (IEEE 802.3ad, IEEE 802.1ax) and LLDP-based (IEEE 802.1ab) topology discovery to the Basebox setup.
CAWR uses LLDP to detect internal links (connections between the switches) to build an initial topology. 
Ports (bonds) that are configured in the 'externalports' field of 'cawr_config.yaml' file or on which LACP messages have been received are added to the topology as well.

Example for configured port/bond in 'cawr_config.yaml':

```
externalports:
# max length for interfacename is 15 characters; MAC has the form: 99:AA:BB:CC:DD:EE:FF;  0 is not valid for dpid or port; hex values have to start with "0x"

# attaches a single port
#- [interfacename, MAC, dpid, port]
- [ configuredport1, AB:AB:67:BB:01:BB, 0x290200182330dff6, 47 ]

# attaches a bond port
#- [interfacename, MAC, dpid1, port1, dpid2, port2]
- [ configuredbond1, AC:AC:23:CA:CA:CA, 0x290200182330dff6, 37, 0x290200182330dea2, 41 ]

```

If LLDP is configured on a server (e.g. via LLDPd) the LLDP information (system name) is used and displayed in the GUI. If host/bond mapping is set in the 'cawr_config.yaml' file, the LLDP information is ignored. If neither of the above is available, the bonds are attached to an 'unknown' host.

More information about LLDPd can be found in the [LLDPd documentation][lldpd]. Below a simple example configuration file is shown (to put into /etc/lldpd.conf):

```
configure lldp tx-interval 10
configure system interface pattern *,!eno*
```

Finally, LACP is used to continuously monitor the link status and detect port connections and disconnections on servers that have LACP enabled. Ports are removed from the topology when no LACP packets have been received within the timeout. Ports are also removed when the appropriate OpenFlow port status message has been received which is usually much faster than the average LACP trigger. Ports that have LACP configured are taken into the topology when LACP has been received which is usually slower than the OpenFlow port status message.


## Port mapping
As a result of creating the giant switch abstraction, CAWR maps pairs of switch interfaces to a single logical interface.
As a rule, CAWR expects each server to be connected to Basebox using two physical network interfaces. These interfaces must be members of an LACP bond, with one cable going to each of the switches. CAWR detects these bonds and exposes them to baseboxd as a single logical interface.
The naming of this interface takes the following format:

```text
portWWXXYYZZ
```

Where WWXXYYZZ are the last 4 bytes of the bond MAC address (actor MAC address) in hexadecimal notation (on the server, see e.g. `ip link list bond0`).

## Additional resources
* [OF-DPA 2.0][ofdpa]
* [OpenFlow 1.3 specification][of]
* [Revised OpenFlow Library (ROFL)][rofl]
* [LLDPd documentation][lldpd]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](customer_support.html#customer_support)**.

[ofdpa]: https://github.com/Broadcom-Switch/of-dpa (OF-DPA Github link)
[rofl]: https://www.github.com/bisdn/rofl-common (ROFL Github Link)
[of]: https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-switch-v1.3.5.pdf (OpenFlow v1.3 specification pdf)
[lldpd]: https://vincentbernat.github.io/lldpd/usage.html

