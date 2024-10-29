# Prepare VM to run tests locally

To run the tests locally, it's ideal to run them in a shortlived VM. The simplest way is to create a `lxd-ci` profile that you then use when creating the shortlived VM.

## lxd-ci profile

```
name: lxd-ci
description: ""
config:
  cloud-init.user-data: |-
    #cloud-config
    ssh_import_id: [lp:sdeziel]
    apt:
      # Speed things up by not pulling from backports/security and avoid restricted/multiverse pockets.
      # In general, backported packages or those from restricted/multiverse shouldn't be relied on because
      # they don't come with the same level of support as those from main for example.
      # The security repo doesn't make much sense when pulling from a Canonical maintained archive mirror.
      disable_suites:
      - backports
      - security
      conf: |
        # Faster downloads
        Acquire::Languages "none";
        APT::Get::Show-Versions "true";

    # Faster dpkg installs
    write_files:
    - content: "force-unsafe-io\n"
      path: /etc/dpkg/dpkg.cfg
      append: true

    runcmd:
    - echo "PURGE_LXD=1" >> /etc/environment
    # Remove sources of noise
    - systemctl stop unattended-upgrades.service
    - apt-get autopurge -y cron needrestart networkd-dispatcher unattended-upgrades
    - cd /etc/systemd/system/timers.target.wants/ && systemctl disable --now *.timer

    package_update: true
    package_upgrade: true
    packages:
    - debootstrap
    - git
    - gpg
    - jq
    - make
    - qemu-utils
    - rsync
    - squashfs-tools
  limits.cpu: "4"
  limits.memory: 16GiB
  security.devlxd.images: "true"
devices:
  eth0:
    name: eth0
    network: lxdbr0
    type: nic
  lxd:
    path: /root/lxd
    source: /home/sdeziel/git/lxd
    type: disk
  lxd-ci:
    path: /root/lxd-ci
    source: /home/sdeziel/git/lxd-ci
    type: disk
  root:
    path: /
    pool: default
    size: 40GiB
    type: disk
used_by: []
```

> [!NOTE]
> The above profile includes source paths that needs updating to reflect your local environment. Hint: use `$HOME`.

Then it's easy to create a shortlived VM:

```
lxc launch ubuntu-minimal-daily:24.04 v1 --vm -p lxd-ci
```

```
$ lxc shell v1
root@v1:~# cd lxd-ci/
root@v1:~/lxd-ci# ./bin/local-run tests/snapd latest/edge
```

# Running tests locally

To run a test locally (directly where you invoke it), use the `bin/local-run` helper:

```
./bin/local-run tests/interception latest/edge
```

For faster repeated runs, you might want to tell `snap` that it can purge the LXD snap
without taking any snapshot:

```
PURGE_LXD=1 ./bin/local-run tests/interception latest/edge
```

To test a with the exising/already installed LXD snap, you can set the `KEEP_LXD` environment variable.

```
KEEP_LXD=1 ./bin/local-run tests/interception latest/edge
```

Note: if you need to run tests on temporary machines, [Testflinger reservations](https://docs.google.com/document/d/11Kot68mnBY9Wq9DXRzTVrKpx5cMkkhBC5RrM51eyybY) might be useful.

To test a custom build of LXD, you can set the `LXD_SIDELOAD_PATH` environment variable.
This will be copied to `/var/snap/lxd/common/lxd.debug` and the daemon will be reloaded before the test run.

```
LXD_SIDELOAD_PATH=/tmp/lxd ./bin/local-run tests/interception latest/edge
```

To test a custom snap of LXD, you can set the `LXD_SNAP_PATH` environment variable.

```
LXD_SNAP_PATH=/tmp/lxd_0+git.89550582_amd64.snap ./bin/local-run tests/interception latest/edge
```

To run `tests/network-ovn` against various OVN implementation:

```
# Using the deb package from the base Os
OVN_SOURCE=deb PURGE_LXD=1 ./bin/local-run tests/network-ovn latest/edge

# Use numbered releases of MicroOVN
OVN_SOURCE=22.03/edge PURGE_LXD=1 ./bin/local-run tests/network-ovn latest/edge
OVN_SOURCE=24.03/edge PURGE_LXD=1 ./bin/local-run tests/network-ovn latest/edge

# Using the `latest/edge` MicroOVN snap channel
PURGE_LXD=1 ./bin/local-run tests/network-ovn latest/edge
```

# Running tests on OpenStack (ProdStack)

The tests need to be run from PS6's LXD bastion `lxd-bastion-ps6.internal`. Once connected, the proper environment can be loaded with:

```
pe
```

Then to run all the tests on OpenStack VMs:

```
./tests/main-openstack
```

Or to run individual tests (`tests/pylxd` against `latest/edge`):

```
# bin/openstack-run: <serie> <kernel> <test> <args>
./bin/openstack-run jammy default tests/pylxd latest/edge
```

# Running Dell PowerFlex VM storage tests

To run the VM storage tests on the Dell PowerFlex driver, provide the following environment variables:

* `POWERFLEX_POOL`: Name of the PowerFlex storage pool
* `POWERFLEX_DOMAIN`: Name of the PowerFlex domain
* `POWERFLEX_GATEWAY`: Address of the PowerFlex HTTP gateway
* `POWERFLEX_GATEWAY_VERIFY`: Whether to verify the HTTP gateway's certificate. The default is `true`.
* `POWERFLEX_USER`: Name of the PowerFlex user
* `POWERFLEX_PASSWORD`: Password of the PowerFlex user
* `POWERFLEX_MODE`: Operation mode for the consumption of storage volumes. The default is `nvme`.

Ideally use a PowerFlex storage pool (`POWERFLEX_POOL`) which has zero-padding disabled so that the PowerFlex storage driver has to
clear the blocks beforehand.

# Running Pure Storage VM storage tests

To run the VM storage tests using Pure Storage driver, provide the following environment variables:

* `PURE_GATEWAY`: Address of the Pure Storage HTTP gateway
* `PURE_GATEWAY_VERIFY`: Whether to verify the HTTP gateway's certificate. The default is `true`.
* `PURE_API_KEY`: Pure Storage API key.
* `PURE_MODE`: Operation mode for the consumption of storage volumes. The default is `nvme`.

# Infrastructure managed by IS

The PS6 environment has inbound and outbound firewalling applied at the network edge. In order to access some external sites here are the firewall rules we added to firewall maintained by IS:

https://code.launchpad.net/~sdeziel/canonical-is-firewalls/+git/canonical-is-firewalls/+merge/446061

Some HTTP(S) destination also require going through a proxy maintained by IS, here are the proxy rules we added:

https://code.launchpad.net/~sdeziel/canonical-is-internal-proxy-configs/+git/canonical-is-internal-proxy-configs/+merge/446187
