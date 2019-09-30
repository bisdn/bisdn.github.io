TODO: This still to be added

# Test plan

Each image release should pass the following [test plan](somelink.com) .

# Current tests
There are currently total of three l3 test cases and one l2 test cases where the lab setup (controller, switch) needs a specific config in order to work. See the links below for a guide on how to prepare the setup for a certain kind of test.

* [l2 test 1] - Cawr and basebox running on two controllers, HA setup with multiple servers.
* [l3 Test 1] - Single basebox and controller with two connected servers.
* [l3 Test 2](https://gitlab.bisdn.de/basebox/BFG9000/wikis/testing/l3-test-2) - Two separate basebox and controller with manual routes between bbd1 and bbd2.
* [l3 Test 3](https://gitlab.bisdn.de/basebox/BFG9000/wikis/testing/l3-test-2) - Two separate basebox and controller with FRR-BGP.

Note that setting up l3 tests 2 and 3 are done in identical manner.

# Testing
In general we can split all cases into data plane (DP) and control plane (CP).

Control plane tests:

* [Investigate Cbench](http://ctuning.org/wiki/index.php/CTools:CBench)
* Number of routing entries (in unicast routing table). One switch Cumulus manages approx 32k, note differences for different prefix-lengths.
* Rate compression
* Do routes converge?
* BGP router with real BGP network, route Flopping test?
* Extend to multicast/broadcast testing.


Notes for 32k routes test:
Ping all routes, tcp-dump on the receiving end
Check that user data doesn't go through the controller


Data plane tests:

* RFC2544 standard test, see Cisco [link](https://www.cisco.com/c/en/us/td/docs/switches/metro/me1200/config/guide/b_nid_config_book/b_nid_config_book_chapter_01100.pdf) for more 
* UDP test with packet drop as mark for failure. Binary search for the highest speed which consistently drops less than k% packages:
        *  Maximize number of Vlans
	* Maximize number of routes
	* Maximize throughput
	* Combination of the above.

TCP tests. Same as the UDP tests except no control over setting througput.

## Testing methodology
1. Test the test script
 * specify the test scenario (e.g. the no. of VLANs, ports, servers, etc.)
 * make sure that the test runs fine (watch hard-coded sleeps)
2. Try to avoid using 3rd party tools, if you have to use them then test them before
 * make sure that other tools like salt, iperf, etcd works in the specified test scenario and there is no limitations with respect to e.g., max. no./length of salt calls, max. iperf sessions
3. Make tests to test to controller software first (baseboxd/CAWR/etcd_connector)
 * test basic controller functionality first, do stress test the switch later
 * e.g., make sure that pings work, then test iperf with low rate, then increase data rate
4. Take into account hardware limitations
 * make sure that sent traffic does not exceed the max. data rate of the port
 * make sure that a server that was rebooted is up again and configured properly before testing with it (e.g. in reboot test)
5. Test functionality individually
 * e.g., first: test if all flow entries can be written into the switch, only then test sending data

### List of tests to show stability
- everyone is encouraged to add potential test cases
- list can be found [here](https://gitlab.bisdn.de/basebox/BFG9000/wikis/testing/test-cases)

### Available tests
- list of available tests that can be automated using car_ftest
- run on daily/weekly basis
- list can be found [here](https://gitlab.bisdn.de/basebox/BFG9000/wikis/testing/automated-tests)

### Test matrix
| Left Aligned | Centered | Right Aligned | Left Aligned | Centered | Right Aligned |
| :----------- | :------: | ------------: | :----------- | :------: | ------------: |
| Cell 1       | Cell 2   | Cell 3        | Cell 4       | Cell 5   | Cell 6        |
| Cell 7       | Cell 8   | Cell 9        | Cell 10      | Cell 11  | Cell 12       |