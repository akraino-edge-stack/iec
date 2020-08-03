#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath="$(cd "$(dirname "$(readlink -f "$0")")"; pwd)"

IEC_PATH="$(readlink -f "$(cd "${basepath}"; git rev-parse --show-toplevel)")"
HELM_CHARTS_REV_IEC="cord-7.0-arm64"
HELM_CHARTS_REV_REC="cord-7.0-arm64-rec"
UPSTREAM_PROJECT="${UPSTREAM_PROJECT:-iec}"

if [ "$#" -gt 0 ]; then UPSTREAM_PROJECT="$1"; fi

case "${UPSTREAM_PROJECT}" in
  "iec")
    HELM_CHARTS_REV="${HELM_CHARTS_REV_IEC}"
    SEBAVALUES="configs/seba-ponsim-iec-arm64.yaml"
    ;;
  "rec")
    HELM_CHARTS_REV="${HELM_CHARTS_REV_REC}"
    SEBAVALUES="configs/seba-ponsim-rec-arm64.yaml"
    ;;
  *)
    echo "Invalid upstream project ${UPSTREAM_PROJECT}"
    echo "  Specify either iec or rec"
    exit 1
    ;;
esac

export M="/tmp/milestones"
export WORKSPACE="${HOME}"
export SEBAVALUES

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS="${WORKSPACE}/automation-tools"
AUTO_TOOLS_REPO="https://github.com/iecedge/automation-tools.git"
AUTO_TOOLS_REV="${AUTO_TOOLS_VER:-cord-7.0-arm64}"

rm -rf "${M}"
mkdir -p "${M}" "${WORKSPACE}/cord/test"

if ! [ -d "${AUTO_TOOLS}" -o -L "${AUTO_TOOLS}" ]
then
  git clone "${AUTO_TOOLS_REPO}" "${AUTO_TOOLS}"
  (cd "${AUTO_TOOLS}"; git checkout "${AUTO_TOOLS_REV}")
fi

# Use our own helm-charts clone if not already there
CHARTS="${WORKSPACE}/cord/helm-charts"
HELM_CHARTS_REPO="https://github.com/iecedge/helm-charts.git"
if ! [ -d "${CHARTS}" -o -L "${CHARTS}" ]
then
  git clone "${HELM_CHARTS_REPO}" -b "${HELM_CHARTS_REV}" "${CHARTS}"
  (cd "${CHARTS}"; git checkout "${HELM_CHARTS_REV}")
fi

cd "${AUTO_TOOLS}/seba-in-a-box"
# shellcheck source=/dev/null
. env.sh

# Now calling make, to install SiaB and PONSim
make stable
