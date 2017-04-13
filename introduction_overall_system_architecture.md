# Overall system architecture

## Introduction
Basebox is highly modular. Each of its components plays an important role in building an efficient OpenStack networking setup. It delivers high performance alongside scalability, HA and seamless OpenStack integration, while retaining all the benefits of being fully programmable.

## Recommended setup
The fully integrated configuration takes advantage of all of Basebox components.

The control plane and all the logic associated with it resides within [baseboxd][baseboxd_gh] and CAWR. The two are usually located on the same physical device or VM. baseboxd implements all of the standard L2 and L3 network switching and routing functionality. CAWR creates a single big switch abstraction for baseboxd and enables multi-switch scalability.

The configuration information is stored in a highly-available and resilient [etcd][etcd_gh] cluster. Any changes to the configuration stored there are automatically propagated to baseboxd through the [*etcd_connector*][etcd_connector]. This is why the *etcd_connector* has to be co-located with baseboxd. This also makes the etcd our baseboxd configuration API (for details check the API section of the documentation). On the OpenStack side, the [Neutron][neutron_gh] [ML2 plugin][neutron_wiki] writes to our etcd cluster, effectively configuring Basebox.

Down in the data plane we expect each OpenStack compute node to be connected to the Basebox switches with a pair of interfaces (each to a different switch). The interfaces should be configured as an LACP bond. This configuration, again, ensures high performance and adds resilience to the setup.

```text
/overall system architecture/

                                    +--------------------+
                                    |Basebox             |
           +--------------+         | +----------------+ |
           | etcd cluster +-----------> etcd_connector | |
           +-------^------+         | +-------+--------+ |
                   |                |         |          |
+----------------------------+      |    +----v-----+    |
|OpenStack         |         |      |    | baseboxd |    |
|  +---------+-----+------+  |      |    +----+-----+    |
|  | Neutron | ML2 Plugin |  |      |         |          |
|  |         +------------+  |      |      +--v---+      |
|  |                      |  |      |      | CAWR |      |
|  +----------------------+  |      |   +--+------+--+   |
|                            |      |   |            |   |
| +------------------------+ |      +--------------------+
| | OpenStack Compute Node | |          |            |
| |                        | |      +---v----+  +----v---+
| |      ^       ^         | |      | switch <--> switch |
| +------------------------+ |      +---^----+  +---^----+
|        |       |           |          |           |
|        |       +----------------------+           |
|        +------------------------------------------+
|                            |
+----------------------------+

```

## HA setup

CAWR and baseboxd can be run in HA mode with an active/failover-standby configuration.
In the most recent iteration of Basebox production code this is tested using two physical controller host machines, each running its own instances of CAWR and baseboxd.
State integrity is kept by creating a 2-node etcd cluster, with an etcd instance on each hardware box. The failover is triggered by [Keepalived][kad], configured to observe if both hosts are up.

```text
/sample HA setup/

+----------------------------+  +----------------------------+
|controller A                |  |controller B                |
|ACTIVE                      |  |STAND-BY (FAILOVER)         |
|    +--------------------------------------------------+    |
|    |etcd cluster           |  |                       |    |
|    | +-------------+       |  |       +-------------+ |    |
|    | | etcd node A |       |  |       | etcd node B | |    |
|    | +-------------+       |  |       +-------------+ |    |
|    +--------------------------------------------------+    |
|         |                  |  |                 |          |
|         |                  |  |                 |          |
|         |                  |  |                 |          |
| +-------v--------+         |  |         +-------v--------+ |
| | etcd_connector |         |  |         | etcd_connector | |
| +-------+--------+         |  |         +-------+--------+ |
|         |                  |  |                 |          |
|    +----v-----+  +-------+ |  | +-------+  +----v-----+    |
|    | baseboxd |  |keep-  <------>keep-  |  | baseboxd |    |
|    +----+-----+  |alive.d| |  | |alive.d|  +----+-----+    |
|         |        +-------+ |  | +-------+       |          |
|      +--v---+    |         |  |         |    +--v---+      |
|      | CAWR |    |         |  |         |    | CAWR |      |
|      +--+---+    +         |  |         +    +------+      |
|         |                  |  |                            |
+---------|------------------+  +----------------------------+
          v
```

## Customer support
If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our [customer support](customer_support.html#customer_support).

## Additional resources
* [baseboxd github][baseboxd_gh]
* [*etcd_connector* Repository][etcd_connector]
* [etcd GitHub][etcd_gh]
* [etcd Documentation][etcd_docs]
* [Keepalived Website][kad]
* [OpenStack Neutron GitHub][neutron_gh]
* [OpenStack Neutron Wiki][neutron_wiki]

[kad]: http://www.keepalived.org/ (Keepalived Website)
[baseboxd_gh]: https://github.com/bisdn/basebox (baseboxd GitHub Repository)
[neutron_wiki]: https://wiki.openstack.org/wiki/Neutron/ML2 (Neutron ML2 Wiki)
[neutron_gh]: https://github.com/openstack/neutron (Neutron Github)
[etcd_docs]: https://github.com/coreos/etcd/blob/master/Documentation/docs.md (etcd Documentation)
[etcd_gh]: https://github.com/coreos/etcd (etcd Github)
[etcd_connector]: https://gitlab.bisdn.de/basebox/etcd_connector (*etcd_connector* repository)
