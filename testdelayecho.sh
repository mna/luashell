#!/usr/bin/env bash

if [[ $# -ge 2 ]]; then
  sleep "${1}"
  echo -n "${2}"
elif [[ $# -eq 1 ]]; then
  sleep 1
  echo -n "$1"
else
  sleep 1
  cat -
fi
