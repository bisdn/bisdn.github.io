## Test scripts to test Basebox stability - baseboxd + CAWR

### Server
1. restart single interface on a server (simulates cable or port failure)
2. restart bond on a server (simulated network card failure, prerequisite is 1)
3. restart a server (prerequisites are 1+2)
4. configure/unconfigure interfaces
5. configure/unconfigure MACs on certain VLANs
6. start/stop LACP on an interface

### Switch
1. restart ofagent (simulated segfault)
2. restart ofdpa (simulated segfault)
3. flush config (some crazy user interaction)
4. disable switch interconnect

### Controller
1. restart cawr
2. restart baseboxd
3. restart etcd_connector
4. restart etcd
5. configure/unconfigure VLANs on ports in etcd
6. configure/unconfigure ports in etcd
7. restart controller box (involves controller HA procedure)

### Functional

1. dhcp has to work
2. vrrp has to work
3. ...

## Test scripts to test Basebox stability - baseboxd

### Server
1. restart single interface on a server (simulates cable or port failure)
2. restart bond on a server (simulated network card failure, prerequisite is 1)
3. restart a server (prerequisites are 1+2)
4. configure/unconfigure interfaces
5. configure/unconfigure MACs on certain VLANs

### Switch
1. restart ofagent (simulated segfault)
2. restart ofdpa (simulated segfault)
3. flush config (some crazy user interaction)

### Controller
1. restart baseboxd
2. restart etcd_connector
3. restart etcd
4. restart basebox_api
4. configure/unconfigure VLANs on ports in etcd
5. configure/unconfigure ports in etcd
6. Restart FRR

### Functional

1. dhcp has to work
2. vrrp has to  work