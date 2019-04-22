#!/bin/bash -ex
# shellcheck disable=SC2016

function wait_for {
  # Execute in a subshell to prevent local variable override during recursion
  (
    local total_attempts=$1; shift
    local cmdstr=$*
    local sleep_time=2
    echo -e "\n[wait_for] Waiting for cmd to return success: ${cmdstr}"
    # shellcheck disable=SC2034
    for attempt in $(seq "${total_attempts}"); do
      echo "[wait_for] Attempt ${attempt}/${total_attempts%.*} for: ${cmdstr}"
      # shellcheck disable=SC2015
      eval "${cmdstr}" && echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      sleep "${sleep_time}"
    done
    echo "[wait_for] ERROR: Failed after max attempts: ${cmdstr}"
    return 1
  )
}


helm del --purge att-workflow || true
wait_for 100 "test $(helm list 'att-platform' | wc -l) -eq 0"
helm del --purge seba  || true
wait_for 100 "test $(helm list 'seba' | wc  | wc -l) -eq 0"
helm del --purge cord-platform || true
wait_for 100 "test $(helm list 'cord-platform' | wc -l) -eq 0"

