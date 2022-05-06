---
title: OF-DPA Table Size Configuration
parent: Platform Configuration
nav_order: 7
---

## OF-DPA Table Sizes

Broadcom Switches feature internal memory that can be freely assigned to increase available memory for various functions. BISDN Linux 4.6 and later support defining strategies how the memory should be used.

Currently four strategies are supported:

| Strategy    | Description                                    |
|-------------|------------------------------------------------|
| default     | use the platform default                       |
| balanced    | allocate evenly to Layer 2 and Layer 3 tables  |
| layer2      | maximize Layer 2 table size                    |
| layer3      | maximize Layer 3 table size                    |

### Selecting the strategy

The strategy can be changed by editing `/etc/default/ofdpa`

```
# -l, --l2l3mode=L2L3MODE    How to allocate memory to L2/L3 tables
# Valid modes are:
#       default         use platform defaults
#       balanced        allocate evenly to L2 and L3
#       layer2          maximize L2 table size
#       layer3          maximize L3 table size
# example:
# OPTIONS="-l layer2"
OPTIONS=""
```

and adding `-l <strategy>` to OPTIONS.

To apply the new configuration, reboot the switch.

### Resulting Table Sizes

Depending on the selected mode, the following number of entries will be evailable for tables 30 (Unicast Routing) and 50 (Bridging):

| Platform                      | default              | balanced             | layer2               |              layer 3 |
|-------------------------------|----------------------|----------------------|----------------------|----------------------|
| Celestica Questone 2 D3030    | 30:  32k<br>50:  32k | 30: 160k<br>50: 160k | 30:  32k<br>50: 288k | 30: 288k<br>50:  32k |
| Delta AG5648                  | 30:  48k<br>50:  40k | 30:  80k<br>50:  72k | 30:  16k<br>50: 136k | 30: 144k<br>50:  16k |
| Delta AG7648                  | 30:  32k<br>50:  32k | 30: 160k<br>50: 160k | 30:  32k<br>50: 288k | 30: 224k<br>50:  96k |
| Edgecore AS4610 Series        | 30:  32k<br>50:  24k | 30:  32k<br>50:  24k | 30:  12k<br>50:  44k | 30:  52k<br>50:   4k |
| Edgecore EPS202 (AS4630-54PE) | 30:  24k<br>50:  32k | 30:  72k<br>50:  64k | 30:  24k<br>50: 112k | 30: 120k<br>50:  16k |
| Edgecore DCS201 (AS5835-54X)  | 30:  32k<br>50:  32k | 30: 160k<br>50: 160k | 30:  32k<br>50: 288k | 30: 288k<br>50:  32k |
| Edgecore DCS204 (AS7726-32X)  | 30:  32k<br>50:  32k | 30: 160k<br>50: 160k | 30:  32k<br>50: 288k | 30: 288k<br>50:  32k |

These values can be verified with

```
$ client_flowtable_dump -v 30
Table ID 30 (Unicast Routing):   Retrieving all entries. Max entries = 32768, Current entries = 0.
$ client_flowtable_dump -v 50
Table ID 50 (Bridging):   Retrieving all entries. Max entries = 294911, Current entries = 0.
```
