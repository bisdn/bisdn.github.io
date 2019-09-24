## Install saltstack

The examples are given for CentOs and Fedora based OSs, for different OSs please refer to the documentation for your OS of choice.

#### Install salt-master/salt-minion
Install salt-master on your salt-master VM with

```sh
dnf install salt-master
```

Proceed by installing salt-minion on every physical and virtual node (including the salt-master node) in your setup.

```sh
dnf install salt-minion
```

#### Configure salt-minions
We refer to the [salt-minion configuration documentation](https://docs.saltstack.com/en/latest/ref/configuration/minion.html) for help on how to complete the next step.
Configure the ids of your salt-minions which run on VMs by editing ``/etc/salt/miniond_id``. The correct IDs are:

* Salt-master: ftest-master
* Ftest-vm: ftest-vm
* Database-vm: ftest-database

The salt-minions on your hardware nodes may keep their ID, which by default should be the hostname.

Change all minions so that they point to your salt-master IP, by adding
```sh
master: <salt-master IP>
```
to ``/etc/salt/minion``. Remember that you need to accept the minions on the salt-master by using ``salt-key``.

#### Configure salt-master

On ftest-master, clone the [``ftest/ftest-salt``](https://gitlab.bisdn.de/ftest/ftest-salt) and [``ftest/ftest-pillar``](https://gitlab.bisdn.de/ftest/ftest-pillar) repositories, and copy the folders into ``/srv/salt`` and ``/srv/pillar``, respectively.

```sh
git clone git@gitlab.bisdn.de:ftest/ftest-salt.git
git clone git@gitlab.bisdn.de:ftest/ftest-pillar.git
sudo cp -r ftest-salt/* /srv/salt
sudo cp -r ftest-pillar/* /srv/pillar
```

## Provision VMs

When the VMs all have their minions assigned, provisioning is straight forward.
On all VM nodes, run the highstate state

```sh
salt-call state.highstate
```

This will install and start all services needed.
