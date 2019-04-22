#!/bin/bash -ex
# shellcheck disable=SC2016

source util.sh

helm del --purge att-workflow || true
wait_for 100 "test $(helm list 'att-platform' | wc -l) -eq 0"
helm del --purge seba  || true
wait_for 100 "test $(helm list 'seba' | wc -l) -eq 0"
helm del --purge cord-platform || true
wait_for 100 "test $(helm list 'cord-platform' | wc -l) -eq 0"

