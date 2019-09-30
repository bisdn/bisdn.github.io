This article describes the automated tests that can be run using the "car_ftest" test suite. The repository can be found [here] (https://gitlab.bisdn.de/basebox/car_ftest). The test suite comprises a variety of test to measure the quality level of several components of the Basebox product. Basebox was made to run clouds like OpenStack. To test realistically as possible, the suite tries to emulate user actions in a typical cloud environment.

# Setup
Currently (Feb 2018) we use labstack01, labstack02 and bbctrl01. 10 bonds are available that are put into namespaces so that each of them can emulate a server of a data center. 3 VLANs are assigned to each Bond with 3 MACs per VLAN. An iperf full mesh test does then  run 3x3x9x10 iperf sessions. Details to set the interfaces up can be found [here] (https://gitlab.bisdn.de/salt/salt-top/tree/master/basebox-testing/cawr-ns).

# Test procedure
- The test suite uses salt to run several commands on the controllers and servers. It then runs a list of test cases that tests iperf performance. Tests are run on a daily/weekly basis. To test long term stability, several tests are cascaded and run multiple times over a duration of several days. The currently used script can be found [here] (https://gitlab.bisdn.de/basebox/car_ftest/blob/master/bin/send_data_vlan_namespaces.py).

# List of commands

| no. | emulated action                                                                             | ftest command                                                     | status         |
|-----|---------------------------------------------------------------------------------------------|-------------------------------------------------------------------|----------------|
| 1a  | single interface on server is down                                                          | `ip link set *interface* down/up`                                 | working        |
| 1b  | a cable is pulled                                                                           | `ip link set *interface* down/up`                                 | working        |
| 2   | a server is rebooted                                                                        | `ip link set *interface* down/up` for both interfaces of the bond | working        |
| 3   | LACP is stopped on the bond                                                                 | `ip link set *bond* down/up`                                      | working        |
| 4a  | baseboxd is restarted (simulated crash)                                                     | `systemctl stop/start baseboxd`                                   | working        |
| 4b  | cawr is restarted (simulated crash)                                                         | `systemctl stop/start cawr`                                       | working        |
| 5a  | reconfigurations in etcd (remove/add a vid on a port)                                       | `etcdctl rm` or `etcdctl set` commands                            | working        |
| 5b  | reconfigurations in etcd (remove/add a port)                                                | `etcdctl rm` or `etcdctl set` commands                            | integration phase        |
| 6   | restart a switch (restart ofagent/ofdpa)                                                    |                                                                   | in development |
| 7   | 2x random single interfaces down (on different servers, not necessarily on the same switch) | `ip link set *interface* down/up`                                 | working        |
| 8   | all servers/interfaces down/up                                                              | `ip link set *bond* down/up`                                      | working        |
| 9   | idle after sending iperf, bridge fdb entries and flows in bridging table are deleted        | time.sleep(360)                                                   | working        |

# List of test cases

| no. | test case                     | status  | result |
|-----|-------------------------------|---------|--------|
| 1   | iperf (full mesh)             | working | passed |
| 2   | iperf (full mesh) + command 1 | working | passed |
| 3   | iperf (full mesh) + command 2 | working | passed |
| 4   | iperf (full mesh) + command 3 | working | passed |
| 5   | iperf (full mesh) + command 4 | working | passed |
| 6   | max. number of entries in table 50 | | |
| 7   | max. number of entries in table 30 | | |
| 8   | time to write 16K entries in t 30 | | |
| 9   | time to write 32K entries in t 30 | | |