# Running tests locally

To run a test locally (directly where you invoke it), use the `bin/local-run` helper:

```
./bin/local-run tests/interception latest/edge
```

For faster repeated runs, you might want to tell `snap` that it can purge the LXD snap
without taking any snapshot:

```
export PURGE_LXD=1
./bin/local-run tests/interception latest/edge
```

Note: if you need to run tests on temporary machines, [Testflinger reservations](https://docs.google.com/document/d/11Kot68mnBY9Wq9DXRzTVrKpx5cMkkhBC5RrM51eyybY) might be useful.


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

# Infrastructure managed by IS

The PS6 environment has inbound and outbound firewalling applied at the network edge. In order to access some external sites here are the firewall rules we added to firewall maintained by IS:

https://code.launchpad.net/~sdeziel/canonical-is-firewalls/+git/canonical-is-firewalls/+merge/446061

Some HTTP(S) destination also require going through a proxy maintained by IS, here are the proxy rules we added:

https://code.launchpad.net/~sdeziel/canonical-is-internal-proxy-configs/+git/canonical-is-internal-proxy-configs/+merge/446187
