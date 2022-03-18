---
title: OF-DPA Table Size Configuration
parent: Platform Configuration
nav_order: 7
---

## OF-DPA Table Sizes

Broadcom Switches feature internal memory that can be freely assigned to increase available memory for various functions. BISDN Linux 4.5 and later support defining strategies how the memory should be used.

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

Depending on the selected mode, the following number of entries will be evailable:

| Platform                      | default              | balanced             | layer2               |              layer 3 |
|-------------------------------|----------------------|----------------------|----------------------|----------------------|
| Celestica Questone 2 D3030    | L2:  32k<br>L3:  16k | L2: 160k<br>L3: 144k | L2: 288k<br>L3:  16k | L2:  16k<br>L3: 272k |
| Delta AG5648                  | L2:  40k<br>L3:  40k | L2:  40k<br>L3:  40k | L2:  72k<br>L3:   8k | L2:   8k<br>L3:  72k |
| Delta AG7648                  | L2:  32k<br>L3:  16k | L2: 160k<br>L3: 144k | L2: 288k<br>L3:  16k | L2:  96k<br>L3: 208k |
| Edgecore AS4610 Series        | L2:  12k<br>L3:   6k | L2:  12k<br>L3:   6k | L2:  22k<br>L3:   1k | L2:   2k<br>L3:  11k |
| Edgecore EPS202 (AS4630-54PE) | L2:  32k<br>L3:  16k | L2:  64k<br>L3:  64k | L2: 114k<br>L3:  16k | L2:  16k<br>L3: 114k |
| Edgecore DCS201 (AS5835-54X)  | L2:  32k<br>L3:  16k | L2: 160k<br>L3: 144k | L2: 288k<br>L3:  16k | L2:  16k<br>L3: 272k |
| Edgecore DCS204 (AS7726-32X)  | L2:  32k<br>L3:  16k | L2: 160k<br>L3: 144k | L2: 288k<br>L3:  16k | L2:  16k<br>L3: 272k |

These values can be verified with

```
$ sudo client_drivshell config show l2_mem_entries
    l2_mem_entries=32768
$ sudo client_drivshell config show l3_mem_entries
    l3_mem_entries=16384

```
