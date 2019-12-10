# Walkthrough for setting up l3 test 2 and l3 test3.
Start by setting up the interfaces which will be used between bbctrl01 and bbctrl02 and their respective switches.

bbctrl01.labor.bisdn.de
```shell
ip a a 10.250.7.2/24 dev bridge0
```

bbctrl02.labor.bisdn.de
```shell
ip a a 10.250.7.3/24 dev bridge0
```

Now configure the switches to speak to baseboxd on each of the controllers.

for each of the switches, IPs to be found in /var/lib/dnsmasq/dnsmasq.leases on one or both of the controllers. (Currently these are 10.250.7.157(00:18:23:30:de:a2) and 10.250.7.190(00:18:23:30:df:f6))

For each switch IP (If the IPs have changed, refer to the MAC address written in parenthesis) do the following.
```shell
ssh <switch IP>
vi /etc/default/ofagent
```
For switch with IP 10.250.7.157(00:18:23:30:de:a2) set `OPTIONS="-t 10.250.7.2:6654 -m"` and for switch with IP 10.250.7.190(0:18:23:30:df:f6) set `OPTIONS="-t 10.250.7.3:6654 -m"`

Then we flush the flow tables and restart ofdpa:
```shell
client_cfg_purge && systemctl restart ofagent
```

And finally we should (probably) reboot the switches, and on each of the controllers restart basebox and make sure cawr is not running:

```shell
systemctl stop cawr
systemctl restart baseboxd
```

Note that it is important that the correct switch is connected to the correct controller, because the salt states for testing contains mappings for the port numbers on the controllers. This will probably not be necessary once we use FRR, but for now we set routes on controllers manually using salt states.


Lastly remember a few things to check:
```shell
cat /proc/sys/net/ipv4/ip_forward
```
should output `1`. If not, please set it by running

```shell
echo 1 > /proc/sys/net/ipv4/ip_forward
```

I am not sure but sometimes we need to reboot servers. Possibly also controllers.
Now you can safely log into ftest2. Make sure to send your public key to Hilmar or Rubens, and then ssh to the ftest2 vm and run test by running:

```shell
ssh fedora@172.16.254.139
cd /home/fedora/ftest
python3 -m ftest.ftest_hardcode_l3
```