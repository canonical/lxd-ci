# shellcheck shell=bash

# waitSnapdSeed: wait for snapd to be seeded.
# Optional argument: timeout in seconds, defaults to 60.
waitSnapdSeed() (
  { set +x; } 2>/dev/null
  waitSecs="${1:-60}"
  if timeout "${waitSecs}" snap wait system seed.loaded; then
    return 0 # Success.
  fi
  echo "snapd not seeded after ${waitSecs}s"
  return 1 # Failed.
)

# waitInstanceReady: waits for the instance to be ready (processes count > 1).
waitInstanceReady() (
  { set +x; } 2>/dev/null
  maxWait="${MAX_WAIT_SECONDS:-120}"
  instName="${1}"
  instProj="${2:-}"
  if [ -z "${instProj}" ]; then
    # Find the currently selected project.
    instProj="$(lxc project list -f csv | sed -n 's/^\([^(]\+\) (current),.*/\1/ p')"
  fi

  # Wait for the instance to report more than one process.
  processes=0
  for _ in $(seq "${maxWait}"); do
      processes="$(lxc info --project "${instProj}" "${instName}" | awk '{if ($1 == "Processes:") print $2}')"
      if [ "${processes:-0}" -ge "${MIN_PROC_COUNT:-2}" ]; then
          return 0 # Success.
      fi
      sleep 1
  done

  echo "Instance ${instName} (${instProj}) not ready after ${maxWait}s"
  return 1 # Failed.
)

# waitInstanceBooted: waits for the instance to be ready and fully booted.
waitInstanceBooted() (
  { set +x; } 2>/dev/null
  prefix="::warning::"
  if [ "${WARNING_PREFIX:-}" = "false" ]; then
    prefix=""
  fi
  maxWait=90
  instName="$1"
  instProj="${2:-}"
  if [ -z "${instProj}" ]; then
    # Find the currently selected project.
    instProj="$(lxc project list -f csv | sed -n 's/^\([^(]\+\) (current),.*/\1/ p')"
  fi

  # Wait for the instance to be ready
  waitInstanceReady "${instName}" "${instProj}"

  # Then wait for the boot sequence to complete.
  sleep 1
  rc=0
  state="$(lxc exec --project "${instProj}" "${instName}" -- timeout "${maxWait}" systemctl is-system-running --wait)" || rc="$?"

  # rc=124 is when `timeout` is hit.
  # Other rc values are ignored as it doesn't matter if the system is fully
  # operational (`running`) as it is booted.
  if [ "${rc}" -eq 124 ]; then
    echo "${prefix}Instance ${instName} (${instProj}) not booted after ${maxWait}s"
    lxc list --project "${instProj}" "${instName}"
    return 1 # Failed.
  elif [ "${state}" != "running" ]; then
    echo "${prefix}Instance ${instName} (${instProj}) booted but not fully operational: ${state} != running"
  fi

  return 0 # Success.
)

# isSystemdClean: wait for instance to be booted and check for systemd failures.
# ==> Returns 1 if systemd state is clean (no failure), 1 otherwise.
isSystemdClean() (
  { set +x; } 2>/dev/null
  instName="$1"
  instProj="${2:-}"
  if [ -z "${instProj}" ]; then
    # Find the currently selected project.
    instProj="$(lxc project list -f csv | sed -n 's/^\([^(]\+\) (current),.*/\1/ p')"
  fi

  # Wait for the instance to be booted
  waitInstanceBooted "${instName}" "${instProj}"

  # Return 0 if `systemctl --quiet --failed` output is empty, 1 otherwise.
  if [ "$(lxc exec --project "${instProj}" "${instName}" -- systemctl --quiet --failed)" = "" ]; then
      return 0 # Success.
  fi

  # List failed units
  lxc exec --project "${instProj}" "${instName}" -- systemctl --failed
  return 1 # Failed.
)

# enableNICSRIOV: enable SR-IOV on a NIC.
enableNICSRIOV() (
  { set +x; } 2>/dev/null
  parentNIC="${1}"
  numVFS="${2:-"7"}"

  if ! [ -d "/sys/class/net/${parentNIC}" ]; then
      echo "${parentNIC} is not present, wrong name?"
      return 1
  fi

  if ! [ -e "/sys/class/net/${parentNIC}/device/sriov_numvfs" ]; then
      echo "${parentNIC} does not support SRIOV VFs"
      return 1
  fi

  echo "${numVFS}" > "/sys/class/net/${parentNIC}/device/sriov_numvfs"
  ip link set "${parentNIC}" up
  sleep 10
  ethtool "${parentNIC}"
)

# install_deps: install dependencies if needed.
install_deps() (
    { set +x; } 2>/dev/null
    PKGS="${*}"
    missing=""
    PKGS_LIST="$(dpkg --get-selections | awk '{print $1}')"
    for pkg in ${PKGS}; do
        # Many commands are already available on CI runners (like `jq` and
        # `yq`) and are sometimes not installed using deb packages (like `yq`).
        # As such check if a binary of the same name as the package needing to
        # be installed is present.
        # XXX: iptables, nftables and ebtables need special handling due to
        #      using alternative mechanism
        if ! [[ "${pkg}" =~ .*tables ]]; then
            command -v "${pkg}" > /dev/null && continue
        fi

        grep -qxF "${pkg}" <<< "${PKGS_LIST}" && continue
        missing="${missing} ${pkg}"
        break
    done

    if [ "${missing}" != "" ]; then
        apt-get update
        if [ "${INSTALL_RECOMMENDS:-"no"}" = "yes" ]; then
            # shellcheck disable=SC2086
            apt-get install --yes ${PKGS}
        else
            # shellcheck disable=SC2086
            apt-get install --no-install-recommends --yes ${PKGS}
        fi
    fi
)

# install_microceph: install MicroCeph snap.
install_microceph() (
    if snap list microceph 2>/dev/null; then
        snap refresh microceph --channel="${MICROCEPH_SNAP_CHANNEL:-latest/edge}" --cohort=+
    else
        snap install microceph --channel="${MICROCEPH_SNAP_CHANNEL:-latest/edge}" --cohort=+
    fi
)

# configure_microceph: prepare MicroCeph for use by LXD.
configure_microceph() {
    if [ -z "${CEPH_DISK}" ]; then
        echo "Missing disk for use with MicroCeph" >&2
        return 1
    fi

    if [ ! -b "${CEPH_DISK}" ]; then
        echo "${CEPH_DISK} is not a block device" >&2
        return 1
    fi

    if microceph status; then
        return 0
    fi

    microceph cluster bootstrap
    microceph.ceph config set global mon_allow_pool_size_one true
    microceph.ceph config set global mon_allow_pool_delete true
    microceph.ceph config set global osd_pool_default_size 1
    microceph.ceph config set global osd_memory_target 939524096
    microceph.ceph osd crush rule rm replicated_rule
    microceph.ceph osd crush rule create-replicated replicated default osd
    for flag in nosnaptrim nobackfill norebalance norecover noscrub nodeep-scrub; do
        microceph.ceph osd set $flag
    done

    microceph disk add --wipe "${CEPH_DISK}"

    microceph enable rgw
    microceph.ceph osd pool create cephfs_meta 32
    microceph.ceph osd pool create cephfs_data 32
    microceph.ceph fs new cephfs cephfs_meta cephfs_data
    microceph.ceph fs ls
    sleep 30
    microceph.ceph status
    # Wait until there are no more "unknowns" pgs
    for _ in $(seq 60); do
      if microceph.ceph pg stat | grep -wF unknown; then
        sleep 1
      else
        break
      fi
    done
    microceph.ceph status
}

# install_ovn: install OVN packages or MicroOVN snap.
install_ovn() (
    if [ "${OVN_SOURCE:-latest/edge}" = "deb" ]; then
        # Avoid clashing with the microovn snap
        if snap list microovn 2>/dev/null; then
            snap remove --purge microovn
        fi

        install_deps ovn-host ovn-central
    elif ! snap list microovn 2>/dev/null; then
        # Avoid clashing with the deb packages
        apt-get autopurge --yes ovn-host ovn-central || true

        snap install microovn --channel="${OVN_SOURCE:-latest/edge}" --cohort=+
    fi
)

# configure_ovn: prepare OVN for use by LXD.
configure_ovn() {
    if [ "${OVN_SOURCE:-latest/edge}" = "deb" ]; then
        ovs-vsctl set open_vswitch . \
          external_ids:ovn-remote=unix:/var/run/ovn/ovnsb_db.sock \
          external_ids:ovn-encap-type=geneve \
          external_ids:ovn-encap-ip=127.0.0.1

        # Empty controller log so ACL log checks are consistent over repeat runs.
        echo "" > /var/log/ovn/ovn-controller.log
    else
        microovn status || microovn cluster bootstrap
        lxc config set network.ovn.northbound_connection "ssl:127.0.0.1:6641"
    fi
}

# install_lxd: install LXD from a specific channel or `latest/edge` if none is provided.
# Optional argument: boolean which indicates whether to start the daemon. Default is true.
install_lxd() (
    local start_daemon="${1:-true}"

    # Prevent lxd-installer from getting in the way
    [ -x /usr/sbin/lxd ] && chmod -x /usr/sbin/lxd
    [ -x /usr/sbin/lxc ] && chmod -x /usr/sbin/lxc

    # Wait for snapd seeding
    waitSnapdSeed

    if [ -n "${KEEP_LXD:-}" ]; then
        # Make sure LXD is started at least
        systemctl start snap.lxd.daemon.service
    else
        # Prior to removal, snap takes a snapshot of the user data. This is
        # slow and IO intensive so best skipped if possible by a purge.
        if [ -n "${PURGE_LXD:-}" ]; then
            snap remove --purge lxd || true
        fi

        # Installing a locally provided snap requires to first install from the
        # snapstore then install with --dangerous. The alias needs to be created
        # manually too.
        if [ -n "${LXD_SNAP_PATH:-}" ]; then
            snap list lxd 2>/dev/null || snap install lxd --channel "${LXD_SNAP_CHANNEL}" --cohort=+
            snap install --dangerous "${LXD_SNAP_PATH}"
            snap alias lxd.lxc lxc
        else
            if snap list lxd 2>/dev/null; then
                snap refresh lxd --channel="${LXD_SNAP_CHANNEL}" --cohort=+
            else
                snap install lxd --channel="${LXD_SNAP_CHANNEL}" --cohort=+
            fi
        fi
    fi

    snap list lxd
    uname -a
    cat /proc/cmdline

    if [ -n "${LXD_SIDELOAD_PATH:-}" ]; then
        cp "${LXD_SIDELOAD_PATH}" /var/snap/lxd/common/lxd.debug
    fi

    if [ -n "${LXC_SIDELOAD_PATH:-}" ]; then
        cp "${LXC_SIDELOAD_PATH}" /var/snap/lxd/common/lxc.debug
    fi

    if [ -n "${LXD_AGENT_SIDELOAD_PATH:-}" ]; then
        mount --bind "${LXD_AGENT_SIDELOAD_PATH}" /snap/lxd/current/bin/lxd-agent
    fi

    if [ "$start_daemon" = "true" ]; then
        lxd waitready --timeout=300
    fi

    # Silence the "If this is your first time running LXD on this machine" banner
    # on first invocation
    mkdir -p ~/snap/lxd/common/config/
    touch ~/snap/lxd/common/config/config.yml
)

# install_snapd: install snapd from a specific channel or the default if none is provided.
install_snapd() (
    local SNAPD_SNAP_CHANNEL="${1:-}"
    local action="install"
    # Wait for snapd seeding
    waitSnapdSeed

    # check if snapd is already installed
    if snap list snapd 2>/dev/null; then
        action="refresh"
    fi

    if [ -n "${SNAPD_SNAP_CHANNEL:-}" ]; then
        snap "${action}" snapd --channel "${SNAPD_SNAP_CHANNEL}" --cohort=+
    else
        snap "${action}" snapd
    fi
)

# hasNeededAPIExtension: check if LXD supports the needed extension.
hasNeededAPIExtension() (
    { set +x; } 2>/dev/null

    needed_extension="${1}"

    lxc info | grep -qxFm1 -- "- ${needed_extension}"
)

# runsMinimumKernel: check if the running kernel is at least the minimum version.
runsMinimumKernel() (
    min_version="${1}"
    min_major="$(echo "${min_version}" | cut -d. -f1)"
    min_minor="$(echo "${min_version}" | cut -d. -f2)"
    running_version="$(uname -r | cut -d. -f 1,2)"
    running_major="$(echo "${running_version}" | cut -d. -f1)"
    running_minor="$(echo "${running_version}" | cut -d. -f2)"

    if [ "${running_major}" -lt "${min_major}" ]; then
        return 1
    elif [ "${running_major}" -eq "${min_major}" ] && [ "${running_minor}" -lt "${min_minor}" ]; then
        return 1
    fi
    return 0
)

# createPowerFlexPool: creates a new storage pool using the PowerFlex driver.
createPowerFlexPool() (
  lxc storage create "${1}" powerflex \
    powerflex.pool="${POWERFLEX_POOL}" \
    powerflex.domain="${POWERFLEX_DOMAIN}" \
    powerflex.gateway="${POWERFLEX_GATEWAY}" \
    powerflex.gateway.verify="${POWERFLEX_GATEWAY_VERIFY:-true}" \
    powerflex.user.name="${POWERFLEX_USER}" \
    powerflex.user.password="${POWERFLEX_PASSWORD}" \
    powerflex.mode="${POWERFLEX_MODE:-nvme}"
)

# createPureStoragePool: creates a new storage pool using the Pure Storage driver.
createPureStoragePool() (
  lxc storage create "${1}" pure \
    pure.gateway="${PURE_GATEWAY}" \
    pure.gateway.verify="${PURE_GATEWAY_VERIFY:-true}" \
    pure.api.token="${PURE_API_TOKEN}" \
    pure.mode="${PURE_MODE:-nvme}"
)

# createCertificateAndKey: creates a new key pair.
createCertificateAndKey() (
  key_file="${1}"
  crt_file="${2}"
  cn="${3}"
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 -keyout "${key_file}" -nodes -out "${crt_file}" -days 1 -subj "/CN=${cn}"
)

# certificateFingerprint: returns the certificate's fingerprint.
certificateFingerprint() (
  openssl x509 -in "${1}" -outform der | sha256sum
)

# certificateFingerprintShort: returns the certificate's fingerprint in short form as used by LXD.
certificateFingerprintShort() (
  certificateFingerprint "${1}" | head -c12
)

# setup_swap: create a temporary swapfile for lxd-ci usage but only if there is no existing swap.
setup_swap() {
    if [ "$(swapon --noheading --raw)" != "" ]; then
        # Swap detected, nothing to do
        return
    fi

    SIZE="${1:-1G}"
    LXD_CI_SWAPFILE="$(mktemp --tmpdir lxd-ci.swapfile.XXXXXXX)"
    fallocate -l "${SIZE}" "${LXD_CI_SWAPFILE}"
    chmod 0000 "${LXD_CI_SWAPFILE}"
    mkswap "${LXD_CI_SWAPFILE}"
    swapon "${LXD_CI_SWAPFILE}"
    export LXD_CI_SWAPFILE
}

# teardown_swap: deactivate and remove any swapfile created by lxd-ci
teardown_swap() {
    if [ -z "${LXD_CI_SWAPFILE:-}" ]; then
        return
    fi

    swapoff "${LXD_CI_SWAPFILE}"
    rm "${LXD_CI_SWAPFILE}"
}


# cleanup: report if the test passed or not and return the appropriate return code.
cleanup() {
    set +e
    echo ""
    if [ "${FAIL}" = "1" ]; then
        echo "Test failed"

        # Displaying a wall of text is OK in CI but best avoided when running locally
        if [ -n "${GITHUB_ACTIONS:-}" ]; then
            echo "::group::diagnostic"
            # Report current disk usage to diagnose potential out of space issues
            df -h

            # Report some more information for diagnostic purposes
            snap list --all
            uname -a
            if echo "${LXD_SNAP_CHANNEL}" | grep -qE '^4\.0/'; then
                lxc list
            else
                lxc list --all-projects
            fi
            echo "::endgroup::"

            echo "::group::lsmod"
            lsmod
            echo "::endgroup::"

            echo "::group::meminfo"
            cat /proc/meminfo
            echo "::endgroup::"

            echo "::group::mountinfo"
            cat /proc/1/mountinfo
            echo "::endgroup::"

            # LXD daemon logs
            echo "::group::lxd logs"
            journalctl --quiet --no-hostname --no-pager --boot=0 --lines=100 --unit=snap.lxd.daemon.service
            echo "::endgroup::"

            # dmesg may contain oops, IO errors, crashes, etc
            echo "::group::dmesg logs"
            journalctl --quiet --no-hostname --no-pager --boot=0 --lines=100 --dmesg
            echo "::endgroup::"
        fi

        exit 1
    fi

    # Teardown any swapfile created by lxd-ci
    teardown_swap

    echo "Test passed"
    exit 0
}

# Only if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  @@LXD_SNAP_CHANNEL@@
  export DEBIAN_FRONTEND=noninteractive
  FAIL=1
  trap cleanup EXIT HUP INT TERM
fi
