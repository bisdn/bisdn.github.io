# Welcome to basebox documentation!

Basebox is the BISDN Linux package for data center networks with three freely combinable elements:
* Baseboxd is a controller daemon integrating whitebox switches into Linux.
* The CAWR controller (Capability AWare Routing) is an optional shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. It implements multi-path routing and multi-chassis link aggregation.
* We offer BISDN Linux, a Yocto-based operating system for selected whitebox switches.
* We provide OpenStack integration of baseboxd via a neutron ML2 plugin.
Basebox can either run directly on the switch or in a separate controller machine. The solution addresses issues of orchestration, flexibilization and further automation in various scenarios.

Baseboxd is using the OpenFlow Data Path Abstraction (OF-DPA 2.0), such as ONL, and essentially translates OpenFlow into Linux netlink and vice versa.
Baseboxd supports any OF-DPA 2.0 whitebox switch.

To find out more please refer to the following resources.

## Introduction to Basebox
* [Overall System Overview](introduction_overall_system_architecture.html)
* [Baseboxd](introduction_baseboxd.html)
* [CAWR](introduction_cawr.html)
* [ML2 Plugin](introduction_ml2_plugin.html)
* [BISDN Linux](introduction_bisdn_linux.html)

## Installation and Setup
* [Installation topic 1]()
* [Installation topic 2]()

## API
* [API topic 1]()
* [API topic 2]()
