.. _ftest_intro::

What is ftest
=============

ftest is a `Python3 module <https://docs.python.org/3/tutorial/modules.html>`_ to automate testing for baseboxd. Employing `Saltstack <https://www.saltstack.com>`_
for remote command execution, ftest allows us to quickly provision an entire lab network, run connectivity tests, and provide test output in a readable way
(and posts to a slack channel, for convenience).

The ftest module makes REST-calls to the salt-master containing commands to its salt-minions. To collect these commands we use `salt states <https://docs.saltstack.com/en/getstarted/fundamentals/states.html>`_. Every such call is then stored in a database to which the ftest module is listening, waiting for the call to finish so it can use the result of the call that was made.

Lab setup
=========

Below is a diagram of the test setup in the BISDN lab. This test setup was designed to maximise the possibilities we have for testing, where we have a leaf-spine
architecture for the networking devices, simulating, on a smaller scale, real Data center deployments.

.. image:: testbed/images/ftest_general_setup.png
  :scale: 30 %
  :align: center

The servers (labstack0X) have multiple NICs providing multiple ports, which we then leverage the network namespaces in Linux to simulate multiple hosts/ VMs.

.. image:: testbed/images/lab_setup.png 
  :scale: 70 %
  :align: center

ftest configuration
===================

ftest has a configuration file, usually present in /etc/ftest/ftest.conf. This file describes the relevant configurations for proper ftest execution, since
this tool depends on access to a Postgres database, the salt-master, among others. Log level can also be changed in this file.

For runtime configuration, ftest defines a collection of CLI arguments.

.. code-block:: bash

  Options:
  --test-type <test-name> ... : Defines the list of test types to be executed. Multiple test types can be queued simply by writing multiple tests names separated
  by a space.
  --minions <salt minion id> : Defines a list of targets for the test, separated by a space. The names provided here should be the same names as the salt-minion
  ids.
  --hours <number of hours> : Defines the number of hours that *each* test will run for. This argument is used instead of runs.
  --runs <number of runs> : Defines the number of runs that *each* test will run for. This argument is used instead of hours.
  --config <config file location> : Select a different config file rather than the default location of /etc/ftest/ftest.conf.
  --teardown : Select if the interfaces should be teardown after the test runs.
  --slack: Select if the test results should be posted to slack at the end of the test.

Test run chronology
===================

Running a single test, or a series of different tests is executed as shown in the example below containing two tests, **Test 1** and **Test 2**.

* Initialise nodes (controllers, switches, servers)
    * Provision nodes (Install and check basebox version)
      * Setup topology for test 1
        * Run test (i.e. Ping or Iperf)
        * Store test results
        * Make changes (i.e. interface up/down, restart node)
        * Repeat
        * Teardown topology and post results for test 1
      * Setup topology test 2 
        * Run test (i.e. Ping or Iperf) 
        * Store test results test 2
        * Make changes (i.e. interface up/down, restart node)
        * Repeat
      * Teardown topology and post results for test 2
  * Exit Ftest

Posting and checking results
============================

Adding a ``--slack`` will automatically post a notification of the test starting and a result as soon as the test is done. There is also a results folder in the ftest directory which can be viewed in your browser on ftest:8000

If the http server is not running, you can start it by going into the ftest directory and running

.. code-block:: bash

  python3 -m http.server 8000
