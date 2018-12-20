Welcome to Basebox documentation!
---------------------------------

Basebox is the BISDN controller package for data center networks with the following combinable elements:
        * The BISDN Linux Distribution is a Yocto-based operating system for selected whitebox switches
        * baseboxd is a controller daemon integrating whitebox switches into Linux
        * The CAWR controller (Capability AWare Routing) is an optional shim OpenFlow controller that creates a giant switch abstraction from a set of whitebox switches. It implements multi-path routing and multi-chassis link aggregation
        * OpenStack integration of baseboxd can be done via a Neutron ML2 plugin
Basebox can either run directly on the switch or in a separate controller machine. The solution addresses issues of orchestration, flexibilization, high availability and further automation in various scenarios.

Please find the installation guide, API definitions and additional resources below.

Customer support
++++++++++++++++

If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our  :doc:`customer_support`.

BISDN Linux:
++++

.. toctree::
      :glob:

   introduction/introduction_bisdn_linux
   setup/install_switch_image
   setup/advanced_setup
   setup/package_management

baseboxd:
++++

.. toctree::
      :glob:

   introduction/introduction_baseboxd
   setup/setup_standalone
   setup/setup_examples
   setup/setup_examples_advanced

Basebox Fabric:
++++
.. toctree::
      :glob:

   introduction/introduction_overall_system_architecture
   introduction/introduction_cawr
   introduction/introduction_ml2_plugin
   setup/setup_physical
   api/basic_commands
   api/api_definition
   api/api_clients
   gui/introduction

Known issues:
++++
.. toctree::
      :glob:

   setup/known_issues

