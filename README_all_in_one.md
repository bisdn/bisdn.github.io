# README for BISDN Linux Switch Image

We assume that the ONIE installation of the switch image was successful. For more information on ONIE installation please refer to the README\_ONIE in the same directory. 

## Getting started 

BISDN Linux makes use of systemd, so there are a handful of services that get the networking running:
	- ofdpa
	- ofdpa-grpc
	- ofagent
	- baseboxd
	- frr

You may start/stop/query these services:

#>systemctl start ofdpa
#>systemctl stop ofdpa
#>systemctl status ofdpa

BISDN Linux contains the prerequisites to control the switch by either local or remote OpenFlow controllers.
The local OpenFlow Agent can connect to a controller endpoint specified in the file

/usr/default/ofagent 
The line 
OPTIONS="-t 127.0.0.1:6653 -m"

should be changed to point to any remote controller address and TCP port number.

After you have modified the file, make sure to restart the ofagent service. 

#>systemctl restart ofagent

##baseboxd

Following this, start the baseboxd controller (or make sure it is running locally).

#>systemctl restart baseboxd

After a short while (1 to 2 seconds) you should see the list of switch ports being exposed to the local host.

#>ip link show

Note that the ports that you see (port1, port2, ... port54) are numbered as on the switch. The ports are Linux tap devices by nature, and are not the real physical ports (remember, there is a separation of control and data in SDN, the tap interfaces are merely handles for the "real" physical ports on the switch. Therefore, dumping all traffic coming in to a specific port via, e.g., tcpdump, will not give the desired effect unless you have created an OpenFlow rule to literally send all traffic coming in to a certain port up to the controller. For most switches, the data rate even of a 10G port would be too high to pipe all traffic through the OpenFlow channel)

You can look at the output log of baseboxd by means of 

#>journalctl -u baseboxd -f

Note that this works for all other services, too. Sometimes it is particularly helpful to look at the output of the ofdpa service, as this contains some useful output from the client_drivshell command line interface.




##onlpdump
  41  NONE
  42  NONE
  43  10GBASE-CR      Copper          2m     Amphenol          610530004         APF15510044P20  
  44  NONE
  45  10GBASE-SR      Fiber                  x-ion             SFP-10GSR-85      E0707240349     
  46  NONE
  47  10GBASE-SR      Fiber                  x-ion             SFP-10GSR-85      E0707240348     
  48  NONE
  49  NONE
  50  NONE

