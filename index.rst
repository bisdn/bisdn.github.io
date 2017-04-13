Welcome to basebox documentation!
---------------------------------

Basebox is the BISDN Linux package for data center networks with three freely combinable elements:
        * Baseboxd is a controller daemon integrating whitebox switches into Linux.
        * The CAWR controller (Capability AWare Routing) is an optional shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. It implements multi-path routing and multi-chassis link aggregation.
        * We offer BISDN Linux, a Yocto-based operating system for selected whitebox switches.
        * We provide OpenStack integration of baseboxd via a neutron ML2 plugin.
Basebox can either run directly on the switch or in a separate controller machine. The solution addresses issues of orchestration, flexibilization and further automation in various scenarios.

Please find the installation guide, API definitions and additional ressources below.

Customer support
++++++++++++++++

If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our [customer support](customer_support.html#customer_support).

Introduction to Basebox:
++++++++++++++++++++++++

.. toctree::
      :glob:

   introduction_overall_system_architecture
   introduction_baseboxd
   introduction_cawr
   introduction_ml2_plugin
   introduction_bisdn_linux

Installation and Setup:
+++++++++++++++++++++++

.. toctree::
      :glob:

   setup_physical

API:
++++
.. toctree::
      :glob:

   api_definition
   api_clients
