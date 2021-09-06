---
title: OF-DPA Client Tools
parent: Tools
nav_order: 2
---

# OF-DPA Client Tools

These tools enable you to interact with the OF-DPA layer and can be used to cross-check controller behavior and configuration. The following commands can be used to show the flow, group tables and ports, respectively:

```
client_flowtable_dump
client_grouptable_dump
client_port_table_dump
client_drivhsell
```

## ACL table entry management

The access-control list (ACL) table, i.e. table 60, is internally used by baseboxd to handle special types of traffic, such as flooded ARP or LLDP packets.
However, this table supports OpenFlow byte and packet counters for each existing table entry (contrary to the other OFDPA tables, where those are not available). These statistics can be seen by using the `-s` flag in the `client_flowtable_dump` tool:

```
client_flowtable_dump -s 60
```

The visualization of these statistics enables users to monitor network traffic by creating fine-grained OpenFlow match-based flow entries.
These table entries can be installed without any action on matched packets (for passive statistics collection) or they can be configured to be sent to the controller (`baseboxd`).

Packets sent to the controller can be seen in the kernel space, e.g. when using `tcpdump` on the created Linux tap interfaces, as they are not directly forwarded through their egress port. However, these packets are still forwarded to its egress destination by the controller.

**Warning**: Forwarding packets to controller comes with the cost of adding two additional bandwidth-limited and slower hops on the packets' path (when compared to the switch ASIC). While testing, we observed an increase of latency per packet by two orders of magnitude, as well as the increase of the switch CPU load.
{: .label .label-yellow }

The `ofdpa_acl_flow_cli.py` tool can be used to manage the traffic monitoring ACL table entries. This tool receives as command line arguments the flow match fields and respective values, alongside with the add/delete operation identifier, `-a/--add` and `-d/--delete`, respectively.
A list of all the supported fields can be consulted through the `--help` option:

```
ofdpa_acl_flow_cli.py --help
```

The `controller` attribute adds the send to controller instruction to new flows.
Moreover, to easily identify the installed flows, the `cookie` attribute can be set on each flow. This allows the deletion of table entries by only specifying its cookie identifier (instead of all matching attributes).
Yet, this attribute needs to be uniquely set for each flow, as it will not be possible to delete two or more flows with the identifier.

**Warning**: Do not forget to delete flows sent to controller after they are not needed anymore. Packets sent to controller are processed through the switch CPU and not the ASIC, leading to higher latency and limited bandwidth.
{: .label .label-yellow }

Each packet can only be matched on one flow entry, so the table flow rules need to be correctly defined. In addition, when adding/deleting table entries, the [OFDPA table type pattern (TTP) guidelines](https://github.com/Broadcom-Switch/of-dpa/blob/master/OFDPAS-ETP100-R.pdf) must be followed, as previously mentioned in the [Basebox introductory section](../basebox.md#openflow).
For example, adding the following entry will result an error:

```
ofdpa_acl_flow_cli.py -a --ipProto 0x01
```

In this case, since the L2 etherType is not defined, it is not possible to match L3 fields in a flow entry. Adding the IPv4 etherType in the match, for example, will make the flow entry valid:

```
ofdpa_acl_flow_cli.py -a --etherType 0x0800 --ipProto 0x01
```

### Examples
#### Adding flows

```
# Ingress traffic on port 7. The ingress port mask must be set, otherwise this field is seen as a wildcard.
ofdpa_acl_flow_cli.py -a --inPort 7 --inPortMask 0xffffffff

# IPv4 traffic from the 192.168.1.0/24 subnet. Flow cookie is set to 10000
ofdpa_acl_flow_cli.py -a --etherType 0x800 --sourceIp4 192.168.1.0 --sourceIp4Mask 255.255.255.0 --cookie 10000

# IPv6 UDP traffic with destination port 5000 from VLAN 10 with an exact VLAN mask.
# Note the VLAN_VID_PRESENT flag (0x1000) on both VLAN ID/mask values, according to the OFDPA specification.
# Cookie is set to 10001.
ofdpa_acl_flow_cli.py -a --etherType 0x86dd --ipProto 0x11 --destL4Port 5000 --vlanId 0x100a --vlanIdMask 0x1fff --cookie 10001

# Send ingress traffic from port 8 to the controller
ofdpa_acl_flow_cli.py -a --inPort 8 --inPortMask 0xffffffff --controller --cookie 10002
```

#### Deleting flows

The following commands delete the previously created flows:

```
ofdpa_acl_flow_cli.py -d --inPort 7 --inPortMask 0xffffffff
ofdpa_acl_flow_cli.py -d --cookie 10000
ofdpa_acl_flow_cli.py -d --cookie 10001
ofdpa_acl_flow_cli.py -d --cookie 10002
```


### Troubleshooting

Failure on following the TTP guidelines will result in error messages in the `ofdpa_acl_flow_cli.py` tool.
To troubleshoot errors on flow operations, the verbose setting from the `OFDB` module from `ofdpa` must be increased. This is done by editing the `OPTIONS` variable in the `/etc/default/ofdpa` file:

```
### Configuration options for ofdpa
#
# Set the component for debugging (can be added multiple times),
# valid components are:
#        1 = API
#        2 = Mapping
#        3 = RPC
#        4 = OFDB
#        5 = Datapath
#        6 = G8131
#        7 = Y1731
# e.g. (API and Mapping):
# -c 1 -c 2
#
# debug level 0..4 (all components)
# -d 2
#
# example:
# OPTIONS="-c 1 -c 2 -d 2"
OPTIONS="-c 4 -d 4"
```
These changes are applied by restarting the `ofdpa` service:

```
sudo systemctl restart ofdpa
```

With the new verbose option, error messages regarding the creation of new flows can be followed using `journalctl`, e.g.:

```
sudo journalctl -fu ofdpa
Apr 14 12:37:59 agema-ag7648 ofdpa[10452]: ofdbFlowPolicyAclEntryValidate: Invalid ethertype for IPv6 match fields.
```

## Traffic capture with tcpdump

The `switch_tcpdump` tool allows users to capture ingress traffic on the switch port network interfaces created by `baseboxd` seen in BISDN Linux, e.g. `port1`.
Internally, this is done by adding an ACL table entry matching on the desired ingress port with the [ACL table entry management tool](#acl-table-entry-management) and sending its traffic to controller, capturing traffic with `tcpdump`, and then deleting the created entry from the ACL table.

Since captured traffic is sent to controller, matched packets are not routed directly through the ASIC, therefore we do not recommend doing performance measurements with this tool.

The output of the traffic capture can be written to a file or printed it directly in the command line. In addition, it is possible to filter captured traffic using [the same filter syntax as `tcpdump`](https://www.tcpdump.org/manpages/pcap-filter.7.html).

**Note**: This tool needs to be executed with super user privileges.
{: .label .label-yellow }


### Examples

Capturing traffic in `port2` without writing to a file until user interruption (e.g. until the user presses CTRL-C):

```
switch_tcpdump --inPort port2 --stdout
```

Capture ICMP traffic in `port2` and write the output to `icmp_traffic.pcap` until this file reaches 100 MB:

```
switch_tcpdump --inPort port2 --filePath icmp_traffic.pcap --maxSize 100 --filters icmp
```

Capture TCP traffic in `port2` and write the output to `tcp_traffic.pcap` during 10 seconds:

```
switch_tcpdump --inPort port2 --filePath tcp_traffic.pcap --timeout 10 --filters tcp
```


## Metering

To enforce quality of service (QoS) mechanisms, incoming switch traffic can be classified by assigning different traffic classes and colors to processed packets according to the [DiffServ model](https://tools.ietf.org/html/rfc2475).
This traffic classification can be configured by setting policies according to the packet/byte rate of each flow, which is done with meters in OFDPA.
Meters can then change the color of packets to green, yellow, or red, depending on its configuration.
It is then possible to configure actions that are applied to each color, such as modifying packet headers or dropping packets.

This functionality is described in detail in Section 3.8 in the [OFDPA TTP guidelines](https://github.com/Broadcom-Switch/of-dpa/blob/master/OFDPAS-ETP100-R.pdf).

Meters can be applied by using the `set meter` instruction in the ACL policy table. To apply rules for each traffic color, packets must be sent from the ACL policy table to the _Color-based Actions_ table (after setting up forwarding rules accordingly).

This section describes how to set up and use meters by *a)* using a meter CLI to manage OFDPA meters, *b)* configure flow rules for different traffic colors, and *c)* send traffic from the ACL policy table to a meter and to the color-based actions table.

### Meter command line tool

Meters can be managed by the `ofdpa_meter_cli.py` tool. This CLI can be used to add, delete, list, or retrieve information from existing meters. Its syntax can be consulted through the `--help` option:

```
ofdpa_meter_cli.py --help
```

#### Adding a meter

Meters are added through the `-a` option, followed by the desired meter id. The meter type, rate unit, and band rate/burst size can then be specified as input:
```
Parameters for new meter

  --mode {trtcm,srtcm,mtrtcm}
                        Meter Mode (default srtcm)
  --color               Color aware meter (default is color blind)
  --unit {kbps,pps}     Meter rate unit (default kbps)
  --cir YELLOWRATE      CIR
  --cbs YELLOWBURST     CBS
  --pir REDRATE         PIR
  --pbs REDBURST        PBS

```

The following example adds a two rate three color meter (TrTCM) with ID 20000 measured in Kbps, with a CIR of 100000 Kbps (100 Mbps), a CBS of 3000 KB, a PIR of 900000 Kbps (900 Mbps), and a PBS of 5000 KB:

```
ofdpa_meter_cli.py -a 20000 --color --mode trtcm --cir 100000 --cbs 3000 --pir 900000 --pbs 5000
```

#### Print meters

Existing meters can be seen with the `-g` option. If no meter ID is provided, all meters are printed. To print the previously created meter with ID 20000 the following command can be used:

```
ofdpa_meter_cli.py -g 20000
```

#### Deleting a meter

Meters can be deleted with the `-d` option, followed by a meter ID or by the `--all` option to delete all the meters:

```
# Delete meter 20000
ofdpa_meter_cli.py -d 20000

# Delete all meters
ofdpa_meter_cli.py -d --all
```

### Color-based actions table configuration

The color-based actions table allows the creation of rules matching incoming packet colors, as well as a specified color index (by default, if not specified, this index is 0). This table can be configured with the `ofdpa_color_table_cli.py` tool.

The matching color and index can be defined with the `--color` and `--index` options, respectively:

```
Match fields (add/delete):
  --color color         Packet color (green/yellow/red)
  --index INDEX         Color actions index
```

If no instruction is defined, matching packets are not affected through the rest of the processing pipeline. The following instructions are supported in this table:

```
Instruction fields (add):
  --clearAction         Clear flow action set
  --controller          Send packets to controller
  --trafficClass TRAFFICCLASS
                        Set traffic class
  --vlanPcp VLANPCP     Set VLAN PCP
  --ecn ECN             Set ECN
  --dscp DSCP           Set DSCP

```

#### Adding new entries

New table entries can be added with the `-a` option. The following example creates a rule for each traffic color with the default color index (0). Green traffic is not modified, yellow traffic has its DSCP value set to 4, and red traffic has its actions cleared:

```
# Green traffic is not affected
ofdpa_color_table_cli.py -a --color green
# Yellow traffic gets its DSCP value set to 4
ofdpa_color_table_cli.py -a --color yellow --dscp 4
# Red traffic is dropped
ofdpa_color_table_cli.py -a --color red --clearAction
```

#### Deleting existing entries

Existing table entries can be deleted individually, by matching their color and index, or as a group, by matching an index. In the latter case, all green/yellow/red flows with the given index are deleted.

Flows are deleted using the `-d` option:

```
# Deleting an entry matching incoming red traffic on index 0
ofdpa_color_table_cli.py -d --color red

# Deleting all flows from index 1
ofdpa_color_table_cli.py -d --index 1 --all

# The following commands are equivalent to the one above (using --all)
ofdpa_color_table_cli.py -d --color green --index 1
ofdpa_color_table_cli.py -d --color yellow --index 1
ofdpa_color_table_cli.py -d --color red --index 1
```

### Send traffic to meters

To send traffic to a meter, flow entries in the policy ACL table must be configured with the `set meter` instruction, which is set by the `--meterId` option in the `ofdpa_acl_flow_cli.py`. In addition, to enable color-marked packets to be processed accordingly, they also need to be sent to the color-based actions table (65), using the `--gotoTable` option.

The following example matches IPv4 traffic from the 10.0.0.1 address, sends it to meter 20000 and to the color-based actions table:

```
ofdpa_acl_flow_cli.py -a --cookie 10000 --etherType 0x800 --sourceIp4 10.0.0.1 --sourceIp4Mask 255.255.255.255 --meterId 20000 --gotoTable 65
```

## client_drivshell
``client_drivshell`` executes a BCM command via the
[OF-DPA API](https://github.com/Broadcom-Switch/of-dpa/blob/master/src/include/ofdpa_api.h)
The BCM command is not publicly documented, but calling the command with the
``help`` flag produces the following output:

```
client_drivshell help
Help: Type help "command" for detailed command usage
Help: Upper case letters signify minimal match

Commands common to all modes:
	?                   Display list of commands
	ASSert              Assert
	Attach              Attach SOC device(s)
	BackGround          Execute a command in the background.
	break               place to hang a breakpoint
	BroadSync           Manage Time API BroadSync endpoints
	CASE                Execute command based on string match
	CD                  Change current working directory
	cint                Enter the C interpreter
	ClearScreen         Clear terminal output
	CONFig              Configure Management interface
	CONSole             Control console options
	CoPy                Copy a file
	CPUDB               Update the CPU database
	CTEcho              Send an echo request using CPUTRANS
	CTInstall           Set up transport pointers in CPU transports
	CTSetup             Modify the CPUTRANS setup
	DATE                Set or display current date
	DBDump              Dump the current StackTask CPUDB
	DBParse             Parse a line of CPUDB dumped code
	DeBug               Enable/Disable debug output
	DELAY               Put CLI task in a busy-wait loop for some amount of time
	DEVice              Device add/remove
	DISPatch            BCM Dispatch control.
	Echo                Echo command line
	EXIT                Exit the current shell (and possibly reset)
	EXPR                Evaluate infix expression
	FLASHINIT           Initialize on board flash as a file system
	FLASHSYNC           Sync up on board flash with file system
	FOR                 Execute a series of commands in a loop
	Help                Print this list OR usage for a specific command
	HISTory             List command history
	IF                  Conditionally execute commands
	IPROCRead           Read from IPROC Area
	IPROCWrite          Write to IPROC Area
	JOBS                List current background jobs
	KILL                Terminate a background job
	LED                 Control/Load LED processor
	LOCal               Create/Delete a variable in the local scope
	LOG                 Enable/Disable logging and set log file
	LOOP                Execute a series of commands in a loop
	LS                  List current directory
	MCSCmd              Execute cmd on uC
	MCSDump             Create MCS dumpfile
	MCSLoad             Load hexfile to MCS memory
	MCSMsg              Start/stop messaging with MCs
	MCSStatus           Show MCS fault status
	MCSTimeStamp        Print MCS timestamp data
	MKDIR               Make a directory
	MODE                Set shell mode
	MORe                Copy a file to the console
	MoVe                Rename a file on a file system
	NOEcho              Ignore command line
	Pause               Pause command processing and wait for input
	PRINTENV            Display current variable list
	PROBE               Probe for available SOC units
	PSCAN               Control uKernel port scanning.
	PWD                 Print platform dependent working directory
	RCCache             Save contents of an rc file in memory
	RCLoad              Load commands from a file
	REBOOT              Reboot the processor
	RM                  Remove a file from a file system
	RMDIR               Remove a directory
	RPC                 Control BCM API RPC daemon.
	SAVE                Write data to a file
	SET                 Set various configuration options
	SETENV              Create/Delete a variable in the global scope
	SHell               Invoke a system dependent shell
	SLeep               Suspend the CLI task for specified amount of time
	TIME                Time the execution of one or more commands
	Version             Print version and build information

Commands for current mode:
	AGE                 Set ESW hardware age timer
	Attach              Attach SOC device(s)
	Auth                Port-based network access control
	BIST                Run on-chip memory built-in self tests
	BPDU                Manage BPDU addresses
	BTiMeout            Set BIST operation timeout in microseconds
	BUFfer              MMU config
	CABLEdiag           Run Cable Diagnotics
	CACHE               Turn on/off software caching of tables
	CHecK               Check a sorted memory table
	CLEAR               Clear a memory table or counters
	COLOR               Manage packet color
	COMBO               Control combination copper/fiber ports
	COS                 Manage classes of service
	CounTeR             Enable/disable counter collection
	CustomSTAT          Enable/disable counter collection
	DELete              Delete entry by key from a sorted table
	DETach              Detach SOC device(s)
	DMA                 DMA Facilities Interface
	DmaRomTest          Simple test of the SOC DMA ROM API
	DMIRror             Manage directed port mirroring
	DPLL                DPLL operations on SPI bus
	DSCP                Map Diffserv Code Points
	DTAG                Double Tagging
	Dump                Dump an address space or registers
	EditReg             Edit each field of SOC internal register
	EGRess              Manage source-based egress enabling
	EthernetAV          Set/Display the Ethernet AV characteristics
	EXTernalTuning      External memory automatic tuning
	EXTernalTuning2     External memory automatic tuning 2
	EXTernalTuningSum   External memory automatic tuning (summary)
	FieldProcessor      Manage Field Processor
	FlowTracker         Flowtracker commands
	Getreg              Get register
	GPORT               Get a GPORT id
	H2HIGIG             Convert hex words to higig info
	H2HIGIG2            Convert hex words to higig2 info
	HASH                Get or set hardware hash modes
	HashDestination     Display Hash Destination
	HeaderMode          Get or set packet tx header mode
	HSP                 MMU HSP hierarchy
	IbodSync            Enable/Disable IBOD sync process
	INIT                Initialize SOC and S/W
	Insert              Insert into a sorted table
	INTR                Enable, disable, show interrupts
	IPFIX               IPFIX
	IPG                 Set default IPG values for ports
	IPMC                Manage IPMC (IP Multicast) addresses
	L2                  Manage L2 (MAC) addresses
	L2MODE              Change ARL handling mode
	L3                  Manage L3 (IP) addresses
	LINKscan            Configure/Display link scanning
	LISTmem             List the entry format for a given table
	Listreg             List register fields
	LLS                 MMU LLS hierarchy
	LOOKup              Look up a table entry
	MCAST               Manage multicast table
	MemFirst            Displays first valid memory
	MemNext             Displays next valid memory
	MemSCAN             Turn on/off software memory error scanning
	MemWatch            Turn on/off memory snooping
	MIM                 Manage XGS4 Mac-in-MAC
	MIRror              Manage port mirroring
	MODify              Modify table entry by field names
	ModMap              MODID Remapping
	Modreg              Read/modify/write register
	MPLS                Manage XGS4 MPLS
	MSPI                MasterSPI Read / Write
	MTiMeout            Set MIIM operation timeout in usec
	MultiCast           Manage multicast operation
	OAM                 Manage OAM groups and endpoints
	PacketWatcher       Monitor ports for packets
	PBMP                Convert port bitmap string to hex
	PHY                 Set/Display phy characteristics
	PKTIO               Set/Display TX/PacketWatcher with streamlined pktio driver type
	POP                 Pop an entry from a FIFO
	PORT                Set/Display port characteristics
	PortRate            Set/Display port rate metering characteristics
	PortSampRate        Set/Display sflow port sampling rate
	PortStat            Display port status in table
	PROBE               Probe for available SOC units
	PUSH                Push an entry onto a FIFO
	PVlan               Port VLAN settings
	Qcm                 QCM commands
	RATE                Manage packet rate controls
	RateBw              Set/Display port bandwidth rate metering characteristics
	RegCMp              Test a register value
	RegWatch            Turn on/off register snooping
	REMove              Delete entry by index from a sorted table
	ResTest             Tests for resource manager
	RXCfg               Configure RX settings
	RXInit              Call bcm_rx_init
	RXMon               Register an RX handler to dump received packets
	SCHan               Send raw S-Channel message, get response
	SEArch              Search a table for a byte pattern
	SER                 Performs operations related to Soft Error Recovery
	Setreg              Set register
	SHOW                Show information on a subsystem
	SOC                 Print internal Driver control information
	SRAM                External DDR2_SRAM test control
	STACKMode           Set/get the stack mode
	StackPortGet        Get stacking characteristics of a port
	StackPortSet        Set stacking characteristics of a port
	STG                 Manage spanning tree groups
	STiMeout            Set S-Channel timeout in microseconds
	STKMode             Hardware Stacking Mode Control
	StkTask             Stack task control
	SwitchControl       General switch control
	TCAM                TCAM control
	TeCHSupport         Collects information required to debug a given feature or subfeature
	TRUNK               Manage port aggregation
	TX                  Transmit one or more packets
	TXBeacon            txbeacon tests
	TXCount             Print current TX statistics
	TXSTArt             Transmit one or more packets in background
	TXSTOp              Terminate a previous "txstart" command
	VLAN                Manage virtual LANs
	WARMBOOT            Optionally boot warm
	WLAN                Manage XGS4 WLAN
	Write               Write entry(s) into a table
	XAUI                Run XAUI BERT on specified port pair

Dynamic commands for all modes:
	xmem                xmem r addr: read 4 bytes from address
xmem w addr data: write 4 bytes data to address


Number Formats:
	[-]0x[0-9|A-F|a-f]+ -hex if number begins with "0x"
	[-][0-9]+           -decimal integer
	[-]0[0-7]+          -octal if number begins with "0"
	[-]0b[0-1]+         -binary if number begins with "0b"

```
