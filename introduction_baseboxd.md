# Baseboxd
Baseboxd is a controller daemon integrating whitebox
switches into Linux. Based on OpenFlow Data Path
Abstraction (OF-DPA), it translates Linux netlink into
switch rules and vice versa. Our solution can be easily
managed and flawlessly integrated in any existing Linux
environment. It can be combined with CAWR for scaling
switch capacity.

Baseboxd is a translator between Linux netlink and OpenFlow
* OpenFlow 1.3 [OF-DPA 2.0](https://github.com/Broadcom-Switch/of-dpa) controller
* Settings made persistent via etcd
* Configurable via iproute2
* ML2-plugin with L2 VLAN support; supports VLAN-filtering bridges
* Written in C++, based on [Revised OpenFlow Library (ROFL)](https://www.github.com/bisdn/rofl-common)
* Available on Github: [www.github.com/bisdn/basebox](www.github.com/bisdn/basebox)
