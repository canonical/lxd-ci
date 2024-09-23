#!/bin/bash

set -e

# Always from Monday to Sunday.
DATESTART=$1 # YYYY-MM-DD
DATEEND=$2 # YYYY-MM-DD

if [ "${DATESTART}" = "" ] || [ "${DATEEND}" = "" ]; then
    echo "Usage: $0 <date_start> <date_end>"
    exit 1
fi

#
# Template that needs to be populated.
#
echo '**Weekly status for the week of <DD>th <MM> to <DD>th <MM>.**'

echo -e "\n# Introduction"
echo -e "\nA few sentences summarizing this week."

echo -e "\n## Feature 1"
echo -e "What it is? How to use it? Link to the docs"
echo -e "Documentation: LINK"

echo -e "\n## Feature 2"
echo -e "What it is? How to use it? Link to the docs"
echo -e "Documentation: LINK"

echo -e "\n## Bugfixes"
echo "- Fixed ..."
echo "- Fixed ..."

#
# Generated, leave as is.
#
echo -e "\n## All changes"
echo -e "\nThe items listed below is all of the work which happened over the past week and which will be included in the next release."

echo -e "\n## LXD"
./github-issues.py canonical/lxd "${1}" "${2}"
sleep 1

echo -e "\n## LXD UI"
./github-issues.py canonical/lxd-ui "${1}" "${2}"
sleep 1

echo -e "\n## LXD Charm"
./github-issues.py canonical/charm-lxd "${1}" "${2}"

echo -e "\n## LXD Terraform provider"
./github-issues.py terraform-lxd/terraform-provider-lxd "${1}" "${2}"

echo -e "\n## PyLXD"
./github-issues.py canonical/pylxd "${1}" "${2}"

echo -e "\n# Distribution work"
echo -e "\nThis section is used to track the work done in downstream Linux distributions to ship the latest LXD as well as work to get various software to work properly inside containers."

echo -e "\n## Ubuntu"
echo -e "* Nothing to report this week."

echo -e "\n## LXD snap"
./github-issues.py canonical/lxd-pkg-snap "${1}" "${2}"
