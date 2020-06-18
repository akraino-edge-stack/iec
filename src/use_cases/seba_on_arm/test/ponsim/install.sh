#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath="$(cd "$(dirname "$(readlink -f "$0")")"; pwd)"

IEC_PATH="$(readlink -f "$(git -C "${basepath}" rev-parse --show-toplevel)")"
HELM_CHARTS_PATH="src/use_cases/seba_on_arm/src_repo/helm-charts"
HELM_CHARTS_REV_IEC="cord-7.0-arm64"
HELM_CHARTS_REV_REC="cord-7.0-arm64-rec"
UPSTREAM_PROJECT="${UPSTREAM_PROJECT:-iec}"

if [ "$#" -gt 0 ]; then UPSTREAM_PROJECT="$1"; fi

case "${UPSTREAM_PROJECT}" in
  "iec")
    HELM_CHARTS_REV="${HELM_CHARTS_REV_IEC}"
    ;;
  "rec")
    HELM_CHARTS_REV="${HELM_CHARTS_REV_REC}"
    ;;
  *)
    echo "Invalid upstream project ${UPSTREAM_PROJECT}"
    echo "  Specify either iec or rec"
    exit 1
    ;;
esac

export M="/tmp/milestones"
export SEBAVALUE=
export WORKSPACE="${HOME}"
export HELM_CHARTS_REV

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS="${WORKSPACE}/automation-tools"
AUTO_TOOLS_REPO="https://github.com/iecedge/automation-tools.git"
AUTO_TOOLS_REV="${AUTO_TOOLS_VER:-cord-7.0-arm64}"

rm -rf "${M}"
mkdir -p "${M}" "${WORKSPACE}/cord/test"

# Update helm-charts submdule needed later
# ignore subproject commit and use latest remote version
git -C "${IEC_PATH}" submodule update --init --remote "${HELM_CHARTS_PATH}"
git -C "${IEC_PATH}/${HELM_CHARTS_PATH}" checkout "${HELM_CHARTS_REV}"

test -d "${AUTO_TOOLS}" || git clone "${AUTO_TOOLS_REPO}" "${AUTO_TOOLS}"
git -C "${AUTO_TOOLS}" checkout "${AUTO_TOOLS_REV}"

# Faking helm-charts repo clone to our own git submodule if not already there
CHARTS="${WORKSPACE}/cord/helm-charts"
test -d "${CHARTS}" || test -L "${CHARTS}" || \
    ln -s "${IEC_PATH}/${HELM_CHARTS_PATH}" "${CHARTS}"

cd "${AUTO_TOOLS}/seba-in-a-box"
# shellcheck source=/dev/null
. env.sh

# Now calling make, to install SiaB and PONSim
make stable
