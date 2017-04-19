Welcome to Basebox documentation!
---------------------------------

Basebox is the BISDN controller package for data center networks with following combinable elements:
        * baseboxd is a controller daemon integrating whitebox switches into Linux
        * The CAWR controller (Capability AWare Routing) is an optional shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. It implements multi-path routing and multi-chassis link aggregation
        * BISDN Linux Distribution is a Yocto-based operating system for selected whitebox switches
        * OpenStack integration of baseboxd can be done via a Neutron ML2 plugin
Basebox can either run directly on the switch or in a separate controller machine. The solution addresses issues of orchestration, flexibilization, high availability and further automation in various scenarios.

Please find the installation guide, API definitions and additional ressources below.

Customer support
++++++++++++++++

If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our  :doc:`customer_support`.

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
