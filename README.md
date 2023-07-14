# Running tests

The tests need to be run from PS6's LXD bastion `lxd-bastion-ps6.internal`. Once connected, the proper environment can be loaded with:

```
pe
```

Then to run all the tests on OpenStack VMs:

```
./tests/main.sh
```

Or to run individual tests (`tests/pylxd` against `latest/edge`):

```
# bin/openstack-run: <serie> <kernel> <test> <args>
./bin/openstack-run jammy default tests/pylxd latest/edge
```

# Infrastructure managed by IS

The PS6 environment has inbound and outbound firewalling applied at the network edge. In order to access some external sites here are the firewall rules we added to firewall maintained by IS:

https://code.launchpad.net/~sdeziel/canonical-is-firewalls/+git/canonical-is-firewalls/+merge/446061

Some HTTP(S) destination also require going through a proxy maintained by IS, here are the proxy rules we added:

https://code.launchpad.net/~sdeziel/canonical-is-internal-proxy-configs/+git/canonical-is-internal-proxy-configs/+merge/446187
