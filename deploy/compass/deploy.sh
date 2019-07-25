#!/bin/bash
set -ex
# deploy VMs
source ./deployVM.sh

# install iec infrastructure
source ./deployIEC.sh

