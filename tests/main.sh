#!/bin/sh

# cgroup
./bin/openstack-run jammy default tests/cgroup
./bin/openstack-run jammy cgroup1 tests/cgroup
./bin/openstack-run jammy swapaccount tests/cgroup

# interception
./bin/openstack-run jammy default tests/interception

# network-bridge-firewall
./bin/openstack-run jammy default tests/network-bridge-firewall

# pylxd
./bin/openstack-run jammy default tests/pylxd latest/edge
./bin/openstack-run jammy default tests/pylxd 5.0/edge
./bin/openstack-run jammy default tests/pylxd 4.0/edge
