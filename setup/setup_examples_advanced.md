# Configure advanced features


# Configure source-MACc learning

Run the following grpc calls to enable/disable source-MAC learning:
```
grpc_cli call localhost:50051 ofdpaSourceMacLearningSet "enable: true"
```

Read the current state:
```
grpc_cli call localhost:50051 ofdpaSourceMacLearningGet ""
```

# Port mirroring

BISDN Linux supports the configuration of mirror ports. Add mirror ports like that (replace localhost with the IP of the whitebox switch)
```
grpc_cli call localhost:50051 ofdpaMirrorPortCreate "port_num: 1"
grpc_cli call localhost:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS}"
grpc_cli call localhost:50051 ofdpaMirrorSourcePortAdd "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }, config: { ofdpa_mirror_port_type: OFDPA_MIRROR_PORT_TYPE_INGRESS_EGRESS}"
```

See mirror port configuration by running the following command on the whitebox switch:

```
client_mirror_port_dump
```

Delete mirror ports like this
```
grpc_cli call localhost:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 2 }"
grpc_cli call localhost:50051 ofdpaMirrorSourcePortDelete "mirror_dst_port_num: { port_num: 1 }, mirror_src_port_num: { port_num: 3 }"
grpc_cli call localhost:50051 ofdpaMirrorPortDelete "port_num: 1"
```


## Additional resources
* [baseboxd GitHub repository][baseboxd]
* [Configuration scripts on GitHub][bbd-examples]

**Customer support**: If at any point during installation or configuration of your Basebox setup you get stuck or have any questions, please contact our **[customer support](../customer_support.html#customer_support)**.

[baseboxd]: https://github.com/bisdn/basebox (baseboxd on github)
[bbd-examples]: https://github.com/bisdn/basebox/tree/master/examples (baseboxd examples on github)
