#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath=$(cd "$(dirname $(readlink -f "$0"))"; pwd)
IEC_PATH="${basepath}/../../../.."
HELM_CHARTS_PATH="src/use_cases/seba_on_arm/src_repo/helm-charts"

export M=/tmp/milestones
export SEBAVALUE=
export WORKSPACE=${HOME}

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS="${WORKSPACE}/automation-tools"
AUTO_TOOLS_REPO="https://github.com/iecedge/automation-tools.git"
AUTO_TOOLS_REV=${AUTO_TOOLS_VER:-cord-7.0-arm64}

rm -rf "${M}"
mkdir -p "${M}" "${WORKSPACE}/cord/test"

# Update helm-charts submdule needed later
# ignore subproject commit and use latest remote version
git -C "${IEC_PATH}" submodule update --init --remote "${HELM_CHARTS_PATH}"


test -d "${AUTO_TOOLS}" || git clone "${AUTO_TOOLS_REPO}" "${AUTO_TOOLS}"
git -C "${AUTO_TOOLS}" checkout "${AUTO_TOOLS_REV}"

# Faking helm-charts repo clone to our own git submodule if not already there
CHARTS="${WORKSPACE}/cord/helm-charts"
test -d "${CHARTS}" || test -L "${CHARTS}" || \
    ln -s "${basepath}/../../src_repo/helm-charts" "${CHARTS}"

cd "${AUTO_TOOLS}/seba-in-a-box"
# shellcheck source=/dev/null
. env.sh

# Now calling make, to install PONSim
make stable
