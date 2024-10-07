#!/bin/bash

set -e

# Set locale time for consistent month names
export LC_TIME="C"

date_to_text() {
    # Extract day and month from the date
    day=$(date -d "$1" +"%d")
    month=$(date -d "$1" +"%B")

    # Remove leading zeros from the day
    day=$((10#$day))

    # Determine the appropriate suffix for the day
    case $day in
    1|21|31) suffix="st" ;;
    2|22) suffix="nd" ;;
    3|23) suffix="rd" ;;
    *) suffix="th" ;;
    esac

    # Return the result in the format "Nth of MonthName"
    echo "${day}${suffix} ${month}"
}

# If end date not provided, assume Monday to Sunday.
DATESTART=$1 # YYYY-MM-DD
DATEEND=${2:-"$(date -d "$1 + 6 days" +"%Y-%m-%d")"} # YYYY-MM-DD

if [ "${DATESTART}" = "" ] || [ "${DATEEND}" = "" ]; then
    echo "Usage: $0 <date_start> <date_end>"
    exit 1
fi

#
# Template that needs to be populated.
#
echo "**Weekly status for the week of $(date_to_text "${DATESTART}") to $(date_to_text "${DATEEND}").**"

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
./github-issues.py canonical/lxd "${DATESTART}" "${DATEEND}"
sleep 1

echo -e "\n## LXD UI"
./github-issues.py canonical/lxd-ui "${DATESTART}" "${DATEEND}"
sleep 1

echo -e "\n## LXD Charm"
./github-issues.py canonical/charm-lxd "${DATESTART}" "${DATEEND}"

echo -e "\n## LXD Terraform provider"
./github-issues.py terraform-lxd/terraform-provider-lxd "${DATESTART}" "${DATEEND}"

echo -e "\n## PyLXD"
./github-issues.py canonical/pylxd "${DATESTART}" "${DATEEND}"

echo -e "\n# Distribution work"
echo -e "\nThis section is used to track the work done in downstream Linux distributions to ship the latest LXD as well as work to get various software to work properly inside containers."

echo -e "\n## Ubuntu"
echo -e "* Nothing to report this week."

echo -e "\n## LXD snap"
./github-issues.py canonical/lxd-pkg-snap "${DATESTART}" "${DATEEND}"
