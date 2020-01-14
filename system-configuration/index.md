---
date: '2020-01-07T16:07:30.187Z'
docname: system-configuration/introduction
images: {}
path: /system-configuration-introduction
title: Topology Overview
nav_order: 7
---

# Overview

The following sections present the intended way to configure several networking scenarios on BISDN Linux.

These examples are designed to be used with up to two Basebox controllers (on-switch) and two physical servers. To increase flexibility Linux namespaces are used to simulate multiple hosts inside the servers. All of the following examples are designed to be executed with the same physical topology, shown in the following diagram.

![topology](/assets/img/topology.png)

This architecture allows to flexibly simulate several networking configurations, across different supported BISDN Linux platforms.
