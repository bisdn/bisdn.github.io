---
title: Source MAC Learning
parent: Platform Configuration
nav_order: 2
---

### Configure source-MAC learning

Source-MAC learning is enabled by default. It is a feature of L2 bridging. For
more information on how a typical switch learns MAC adresses, please refer to
this article: [transparent bridging](https://en.wikipedia.org/wiki/Bridging_(networking)).

In case you do not want the switch to learn MAC addresses automatically, e.g.
when you want to learn them via a specific controller logic, you may disable
this feature.

**Note**: Packets are generally flooded if no learning mechanism is enabled.
{: .label .label-yellow }

To permanently disable source-MAC learning, edit the file /etc/ofdpa-grpc.conf
and add the flag --disable_srcmac_learning to the `OPTIONS=` line, e.g.

```
OPTIONS="--disable_srcmac_learning"
```

Restart ofdpa-grpc to apply changes.

You can also run the following grpc calls to enable/disable source-MAC
learning:

```
grpc_cli call <IP>:50051 ofdpaSourceMacLearningSet "enable: true"
```

Read the current state:

```
grpc_cli call <IP>:50051 ofdpaSourceMacLearningGet ""
```
