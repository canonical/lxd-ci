#!/bin/sh
set -eu

for lxd_snap_channel in "latest/edge" "5.0/edge"; do
  # cgroup
  ./bin/openstack-run jammy default tests/cgroup "${lxd_snap_channel}"
  # XXX: disable test with Jammy's GA kernel configured for cgroup1
  #      https://github.com/canonical/lxd-ci/issues/7
  #./bin/openstack-run jammy cgroup1 tests/cgroup "${lxd_snap_channel}"
  ./bin/openstack-run jammy swapaccount tests/cgroup "${lxd_snap_channel}"

  # interception
  ./bin/openstack-run jammy default tests/interception "${lxd_snap_channel}"

  # network-bridge-firewall
  ./bin/openstack-run jammy default tests/network-bridge-firewall "${lxd_snap_channel}"

  # pylxd
  ./bin/openstack-run jammy default tests/pylxd "${lxd_snap_channel}"

  # storage
  ./bin/openstack-run jammy default tests/storage-disks-vm "${lxd_snap_channel}"
done

# pylxd
./bin/openstack-run jammy default tests/pylxd "4.0/edge"

