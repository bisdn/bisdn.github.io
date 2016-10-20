# CAWR
## Introduction
CAWR – which stands for Capability AWare Routing – is a supplemental shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. This giant switch smoothly integrates with Baseboxd and lets you scale your effective switch capacity. It implements
multi-path routing and supports multichassis link aggregation. CAWR combines a scalable data center switching solution with high availability.

## Architecture
CAWR, as a secondary controller, sits in between baseboxd and the physical switches. Both, its northbound and southbound interfaces, are [OpenFlow][of] and following the [OF-DPA][ofdpa] standard.

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

CAWR implements all the algorithms supporting its internal workflow while employing the [ROFL][rofl] library to interact with OpenFlow traffic.

## Failover
CAWR by design expects a multi-switch configuration (currently tested with 2).
Each server connected to basebox is expected to have a pair of interfaces in bond mode.
CAWR then takes care of routing the layer 2 traffic across the physical network.
CAWR provides failover mechanism to deliver uninterrupted operation even if one of the switches or bond ports goes down.

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

## Topology Discovery (LACP and LLDP)
CAWR adds LACP and LLDP-based topology discovery to the basebox setup.
On startup, CAWR first uses LLDP to detect internal links (ports between switches).
Once the internal topology is mapped it starts looking for LACP beacon messages to discover the servers connected to the switches and configure their bonds. Finally, LACP is used to continously monitor links and detect port connections and disconnection.

## Additional Resources
1. [OF-DPA 2.0][ofdpa]
2. [OpenFlow 1.3 specification][of]
3. [Revised OpenFlow Library (ROFL)][rofl]

[ofdpa]: https://github.com/Broadcom-Switch/of-dpa (OF-DPA Github link)
[rofl]: https://www.github.com/bisdn/rofl-common (ROFL Github Link)
[of]: https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-spec-v1.3.0.pdf (OpenFlow v1.3 specification pdf)
