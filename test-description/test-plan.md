test plan

# Install an image
* Enter "ONIE Rescue" mode
* Install image via `onie-nos-install` (for details see [docs](https://docs.bisdn.de/setup/install_switch_image.html))
* After reboot login as user "root"

# Configure Local/remote controller

* Run the corresponding scripts to configure the switch for Local/remote usage

### Local controller
`basebox-change-config --local`

### Remote controller
`basebox-change-config --remote 172.16.10.10 6653` where the IP-address and port must point to the remote controller

# Check installed software components

Check if the respective software components are installed

### Local controller

To check whether the proper packages are installed run

`opkg info service-name`

The following components should be installed on the switch:
`baseboxd`, `ofagent`, `ofdpa`, `ofdpa-grpc`, `grpc_cli`, `ryu-manager`, `ffr`

e.g.:
```
opkg info baseboxd; \
opkg info ofagent; \
opkg info ofdpa; \
opkg info ofdpa-grpc; \
opkg info grpc_cli; \
opkg info frr; \
opkg info ryu-manager
```

### Remote controller

The following components should be installed on the switch:
`ofagent`, `ofdpa`, `ofdpa-grpc`, `baseboxd`, `grpc_cli`, `ryu-manager`, `ffr`

The following components should be installed on the remote controller:
`baseboxd`, `grpc_cli`, `ffr`, `ryu-manager` (optional)

# Check running services

You can check if the respective services are running.

### Local controller

The following services should be active (running) and enabled on the switch:
`baseboxd`, `ofagent`, `ofdpa`, `ofdpa-grpc`, `grpc_cli`, `ryu-manager`

### Remote controller

The following components should be active (running) and enabled on the switch:
`ofagent`, `ofdpa`, `ofdpa-grpc`

The following components should be inactive and disabled on the switch:
`baseboxd`, `grpc_cli`, `ryu-manager`

The following components should be active (running) and enabled on the remote controller:
`baseboxd`, `grpc_cli`, `ryu-manager`


e.g.:
```
systemctl status baseboxd; \
systemctl status ofagent; \
systemctl status ofdpa; \
systemctl status ofdpa-grpc; \
systemctl status grpc_cli; \
systemctl status ryu-manager
```

# Check ofagent config

`cat /etc/default/ofagent`

The section "OPTION=" should point to localhost (local controller) or to the remote controller and respective port

# Check ip-forwarding

`cat /proc/sys/net/ipv4/ip_forward` should result in `1` \
`cat /proc/sys/net/ipv6/conf/all/forwarding` should result in `1`

# Check values of gc_thresh

should be high (8k+)
```
sysctl net.ipv4.neigh.default.gc_thresh1
sysctl net.ipv4.neigh.default.gc_thresh2
sysctl net.ipv4.neigh.default.gc_thresh3
```

# Check baseboxd
Check if the ports of the switch are shown either on-switch or in the external controller (off-switch)
The `ip l` command should show you all the existing hardware ports

# Client-tools
Check the flow/group-tables

`client_flowtable_dump`
`client_grouptable_dump`

# Check onlpdump

Run `onlpdump` on the switch.

# Check optical modules

tdb.

# Check uninstaller
* Run `onie-bisdn-uninstall -y` for uninstalling the image