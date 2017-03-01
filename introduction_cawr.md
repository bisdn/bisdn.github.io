# CAWR
## Introduction
CAWR – which stands for Capability AWare Routing – is a supplemental shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. This giant switch integrates smoothly with baseboxd and lets you scale your effective switch capacity. It implements multi-path routing and supports multichassis link aggregation (MLAG). CAWR combines a scalable data center switching solution with high availability.

## Architecture
CAWR, as a secondary controller, is placed in between baseboxd and the physical switches. Both, its northbound and southbound interfaces, are [OpenFlow][of] and following the [OF-DPA][ofdpa] standard.

```text
/CAWR control plane /

                           +----------+            +
                           | baseboxd |            |
              +            +--+---+---+            |
logical ports:|            |A | B | C |            |
              +            +--+-^-+---+            | control
                                |                  | plane
                             +--v---+              |
                       +-----> CAWR <-----+        |
                       |     +------+     |        +
                       |                  |
                       |                  |
                 +-----v----+        +----v-----+  +
                 | switch X |        | switch Y |  | data
               + +----------+        +----------+  | plane
physical ports:| |A1| B1 |C1|        |A2| B2 |C2|  |
               + +----------+        +----------+  +

```

CAWR implements all the algorithms supporting its internal workflow, while employing the [ROFL][rofl] library to interact with OpenFlow traffic.

## Failover
CAWR was designed to handle multi-switch configurations. The current version supports up to two switches.
A host can be connected to each of the switches by a pair of interfaces that have bond mode configured.
CAWR then takes care of routing the layer 2 traffic across the physical network and provides failover mechanism to deliver uninterrupted operation even if one of the switches or one of the bond ports goes down or when a cable is broken.
To provide failover, CAWR uses specifice VLAN IDs that can be configured in the "cawr_config.yaml". Failover VLAN IDs must not be used to configure tenant networks in etcd.

```text
/server connectivity/

          +----------+           +
          | baseboxd |           | control
          +----------+           | plane
          |   CAWR   |           |
     +--->+----------+<---+      +
     |                    |
     |                    |
     |                    |
+----v-----+        +-----v----+ +
| switch a <--------> switch b | | data
+-----^----+        +----^-----+ | plane
      |                  |       |
      |    +--------+    |       |
      |    | server |    |       |
      |    +--------+    |       |
      |    |  bond  |    |       |
      |    +--------+    |       |
      |    |P1 || P2|    |       |
      |    +-+----+-+    |       |
      |      |    |      |       |
      +------+    +------+       +
```

## Topology discovery (LACP and LLDP)
CAWR adds LACP and LLDP-based topology discovery to the Basebox setup.
On startup, CAWR first uses LLDP to detect internal links (connections between the switches).
Once the internal topology is mapped it starts looking for LACP beacon messages to discover the servers and their bonds connected to the switches. Finally, LACP is used to continuously monitor the link status and detect port connections and disconnections.


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

[ofdpa]: https://github.com/Broadcom-Switch/of-dpa (OF-DPA Github link)
[rofl]: https://www.github.com/bisdn/rofl-common (ROFL Github Link)
[of]: https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-spec-v1.3.0.pdf (OpenFlow v1.3 specification pdf)

