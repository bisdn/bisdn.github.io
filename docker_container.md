---
title: Docker Container
nav_order: 7
---

# Docker Container

Starting with the 4.0 release, BISDN Linux supports running docker containers
directly on the switch and forwarding traffic either from the management network
or directly from the ASIC towards those containers.

**Note**: All of the traffic directed towards the containers running on the
switch is completely processed in software on the switch controller and there is
no hardware offloading for it. Although the switches are able to run a simple
web service, we do not recommend to run larger workloads (e.g. a full fledged
application that needs some processing power and storage) on the switches. If
you still want to run your application on the switch, please check if enough
resources are available to not interfere with the applications needed to operate
the switch itself (e.g. baseboxd, ofdpa, and ofagent).
{: .label .label-yellow }

All switch images come with a pre-installed docker and preconfigured kernel so
you should not need to reconfigure or install anything. The only thing you need
to do to get started with running docker on switches is to start and enable the
docker daemon itself:

```
sudo systemctl enable docker
sudo systemctl start docker
```

To learn how to work with docker containers, please refer to the official docker
documentation available [here](https://docs.docker.com/get-started/).

If you want to run a simple nginx web server, you can ssh to the switch and run:

```
sudo docker run -d -p --name mynginx 8080:80 nginx:alpine
```

To check the content of the default page locally, you can run:

```
curl localhost:8080
```

To access the page remotely, replace `localhost` with either the IP address on
the management interface of the switch (if you are trying to access it from the
management network) or with any other IP address that is assigned to the switch
itself.

To stop and remove the container you can run:

```
sudo docker stop mynginx
sudo docker rm mynginx
```
