#!/bin/bash

snap_channel="latest/edge"

function parallel() {
        seq 1 $1 | xargs -P $1 -I "{}" "${@:2}"
}

function init() {
	parallel $1 lxc init ubuntu:jammy "t{}" $2
}

function conf() {
	parallel $1 lxc config set "t{}" $2
}

function device_add() {
	parallel $1 lxc config device add "t{}" $2 $3 $4
}

function start() {
	args=""

	for i in $(seq 1 $1); do
		args="t$i $args"
	done

	echo "Start $args"
	lxc start $args
}

function wait() {
	parallel $1 bash -c "while true; do if lxc shell t{}; then break; fi; sleep 1; done"
}

function copy() {
	parallel $1 lxc file push $2 "t{}$3"
}

function cmd() {
	parallel $1 lxc exec "t{}" -- bash -c "$2"
}

function delete() {
	args=""

	for i in $(seq 1 $1); do
                args="t$i $args"
        done

	echo "Delete $args"
	lxc delete -f $args
}

if [[ ! -f $1 ]]
then
	echo "Specify the path to the LXD binary for sideloading"
	exit 1
fi

if [[ ! $(command -v lxc) ]]
then
    snap install lxd --channel $snap_channel
    lxd init --auto
fi

# Test 10 VMs in parallel
init 10 --vm
start 10
delete 10

# Test vsock ID collision
init 10 --vm
conf 10 volatile.vsock_id=42
start 10
delete 10

# Test 5 VMs each with one nested VM
init 5 --vm
start 5
wait 5
cmd 5 "snap wait system seed.loaded && snap refresh lxd --channel $snap_channel"
cmd 5 "lxd init --auto"
copy 5 $1 /var/snap/lxd/common/lxd.debug
cmd 5 "systemctl reload snap.lxd.daemon"
cmd 5 "lxc launch ubuntu:jammy nested --vm"
delete 5

# Test 5 containers each with one nested VM
init 5
conf 5 security.nesting=true
device_add 5 kvm unix-char source=/dev/kvm
device_add 5 vhost-net unix-char source=/dev/vhost-net
device_add 5 vhost-vsock unix-char source=/dev/vhost-vsock
device_add 5 vsock unix-char source=/dev/vsock
start 5
cmd 5 "snap wait system seed.loaded && snap refresh lxd --channel $snap_channel"
cmd 5 "lxd init --auto"
copy 5 $1 /var/snap/lxd/common/lxd.debug
cmd 5 "systemctl reload snap.lxd.daemon"
cmd 5 "lxc launch ubuntu:jammy nested --vm"
delete 5
