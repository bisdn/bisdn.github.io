# CAWR
CAWR – which stands for Capability AWare Routing – is
a supplemental shim OpenFlow controller that creates a
giant switch abstraction from a set of whitebox switches.
This giant switch smoothly integrates with Baseboxd and
lets you scale your effective switch capacity. It implements
multi-path routing and supports multichassis link aggregation.
CAWR combines a scalable data center switching
solution with high availability.

## Architecture

CAWR, as a secondary controller, sits in between baseboxd and the physical switches. It is operated fully through OpenFlow and it is compatible with the OF-DPA flavour.

```text
.                          +----------+            +
                           | baseboxd |            |
              +            +--+---+---+            |
logical ports:|            |A | B |  C|            |
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

## Additional Resources

1. [OF-DPA 2.0](https://github.com/Broadcom-Switch/of-dpa)
2. [OpenFlow 1.3 specification](https://www.opennetworking.org/images/stories/downloads/sdn-resources/onf-specifications/openflow/openflow-spec-v1.3.0.pdf)
3. [Revised OpenFlow Library (ROFL)](https://www.github.com/bisdn/rofl-common)
