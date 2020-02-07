#!/bin/bash
set -o xtrace
set -e

umount /sys/fs/bpf || true
mount bpffs /sys/fs/bpf -t bpf
