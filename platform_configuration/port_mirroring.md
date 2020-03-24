---
title: Port Mirroring
parent: Platform Configuration
nav_order: 1
---

### Port mirroring

BISDN Linux supports the configuration of mirror ports. Add mirror ports like that (replace <IP> with the IP of the whitebox switch or `localhost` when logged in on the switch itself):

```
grpc_cli call <IP>:50051 ofdpaMirrorPortCreate "port_num: 1"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS}"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS_EGRESS}"
```

See mirror port configuration by running the following command on the whitebox switch:

```
client_mirror_port_dump
```

Mirror ports can be deleted according to the following commands:

```
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }"
grpc_cli call <IP>:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }"
grpc_cli call <IP>:50051 ofdpaMirrorPortDelete "port_num: 1"
```

